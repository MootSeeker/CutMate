import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../services/meal_service.dart';
import '../services/ingredient_service.dart';
import 'package:logging/logging.dart';

final _logger = Logger('MealProvider');

/// Provider class for meal recommendation data
class MealProvider extends ChangeNotifier {
  List<Meal> _recommendations = [];
  bool _isLoading = false;
  String _errorMessage = '';
  final MealService _mealService;  double _generationProgress = 0.0; // Tracks generation progress (0-100%)
  DateTime? _lastUpdate; // Tracks when progress was last updated
  
  MealProvider({MealService? mealService}) 
      : _mealService = mealService ?? MealService();
      
  /// All meal recommendations
  List<Meal> get recommendations => _recommendations;
  
  /// Whether meal recommendations are currently being loaded
  bool get isLoading => _isLoading;
  
  /// Error message, if any
  String get errorMessage => _errorMessage;
  
  /// Progress percentage for meal generation (0-100%)
  double get generationProgress => _generationProgress;
  
  /// Initialize the provider with data from storage
  Future<void> initialize() async {
    try {
      // For now, a placeholder to initialize. In the future, this could load saved
      // meals from local storage or a backend service.
      _recommendations = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error initializing meal recommendations: $e';
      notifyListeners();
    }
  }
    // Helper method to update progress with smooth animation
  void _updateProgress(double value) {
    // Don't update for very small changes to avoid too frequent updates
    if ((_generationProgress - value).abs() < 1) return;
    
    // Limit update frequency (not more than once every 200ms)
    final now = DateTime.now();
    if (_lastUpdate != null && now.difference(_lastUpdate!).inMilliseconds < 200) {
      return;
    }
    
    // For smaller changes, just update directly
    if ((_generationProgress - value).abs() < 5) {
      _generationProgress = value;
      _lastUpdate = now;
      notifyListeners();
      return;
    }
    
    // For larger changes, animate smoothly
    _animateProgress(value);
  }
  
  /// Animate the progress to the target value with easing
  void _animateProgress(double targetValue) {
    final startValue = _generationProgress;
    final difference = targetValue - startValue;
    const duration = Duration(milliseconds: 500); // Total animation duration
    const stepDuration = Duration(milliseconds: 16); // ~60fps
    final steps = duration.inMilliseconds ~/ stepDuration.inMilliseconds;
    
    // Use Future.delayed for animation steps
    for (int i = 1; i <= steps; i++) {
      Future.delayed(stepDuration * i, () {
        if (_isDisposed) return; // Skip if provider is disposed
        
        // Calculate progress with easing curve (cubic ease out)
        final t = i / steps; // Linear time from 0-1
        final easedT = 1 - (1 - t) * (1 - t) * (1 - t); // Cubic ease out
        
        _generationProgress = startValue + (difference * easedT);
        notifyListeners();
      });
    }
    
    // Set final value after animation completes
    Future.delayed(duration + const Duration(milliseconds: 10), () {
      _generationProgress = targetValue;
      _lastUpdate = DateTime.now();
      notifyListeners();
    });
  }
  
  /// Get today's recommendation for a specific meal type
  Meal? getRecommendationForMealType(String mealType) {
    if (_recommendations.isEmpty) return null;
    
    // First, try to find meals specifically matching this meal type with high relevance
    final mealTypeRegex = RegExp(mealType, caseSensitive: false);
    final matchingMeals = _recommendations.where(
      (meal) => (mealTypeRegex.hasMatch(meal.name) || mealTypeRegex.hasMatch(meal.description)) && 
      meal.relevanceScore > 0.3
    ).toList();
    
    // If we have high-relevance matching meals, prioritize them
    if (matchingMeals.isNotEmpty) {
      // Sort by relevance score
      matchingMeals.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      
      // Use the timestamp to create a "random" selection among the most relevant matches
      // But with a bias toward the highest-scoring ones
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final maxIndex = matchingMeals.length > 3 ? 3 : matchingMeals.length;
      final selectedIndex = timestamp % maxIndex;
      return matchingMeals[selectedIndex];
    }
    
    // If no high-relevance matching meals, try any match
    final anyMatchingMeals = _recommendations.where(
      (meal) => mealTypeRegex.hasMatch(meal.name) || mealTypeRegex.hasMatch(meal.description)
    ).toList();
    
    if (anyMatchingMeals.isNotEmpty) {
      // Use the timestamp to create a "random" selection
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final maxIndex = anyMatchingMeals.length > 3 ? 3 : anyMatchingMeals.length;
      final selectedIndex = timestamp % maxIndex;
      return anyMatchingMeals[selectedIndex];
    }
    
    // If no matching meals at all, return the most recent recommendation
    return _recommendations.isNotEmpty ? _recommendations.first : null;
  }
  
  /// Get meals by ingredient matching score
  List<Meal> getMealsByIngredientMatch(List<String> ingredients, {int limit = 5}) {
    if (_recommendations.isEmpty || ingredients.isEmpty) return [];
    
    // Calculate relevance scores for all meals based on the provided ingredients
    final scoredMeals = _recommendations.map((meal) {
      final score = IngredientService.calculateIngredientMatchScore(
        meal.ingredients, 
        ingredients
      );
      return meal.copyWith(relevanceScore: score);
    }).toList();
    
    // Sort by relevance score
    scoredMeals.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    
    // Return top matches
    return scoredMeals.where((meal) => meal.relevanceScore > 0.1).take(limit).toList();
  }
  
  /// Get new meal recommendations using the algorithmic OpenFoodFacts meal creation  
  Future<void> getMealRecommendations({
    User? user,
    int count = 1,
    List<String>? preferredIngredients,
    List<String>? availableIngredients,
    List<String>? excludedIngredients,
    Map<String, dynamic>? nutritionGoals,
    String? mealType,
    double? targetCalories,
  }) async {    _isLoading = true;
    _errorMessage = '';
    _generationProgress = 0.0; // Reset progress at start
    _lastUpdate = null;
    notifyListeners();
      // Configure stages for smoother visual feedback - will use these below
    
    try {
      // Use availableIngredients as the basis for algorithmic meal creation
      if (availableIngredients != null && availableIngredients.isNotEmpty) {
        // Log the request for debugging
        _logger.info('Requesting meal recommendations with ingredients: ${availableIngredients.join(", ")}');
          // Update progress - Starting request (10%)
        _updateProgress(10.0);
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Diagnose OpenFoodFacts connectivity issues
        _logger.info('Diagnosing meal recommendation service...');
        
        // Update progress - Intermediate step (15%)
        _updateProgress(15.0);
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Update progress - Checking services (25%)
        _updateProgress(25.0);
        await Future.delayed(const Duration(milliseconds: 150));
        
        // Use the new OpenFoodFacts-based algorithmic meal generation
        _logger.info('Creating meal recommendations with ${availableIngredients.length} ingredients');
        
        // Update progress - Intermediate step (30%)
        _updateProgress(30.0);
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Update progress - Starting meal creation (40%)
        _updateProgress(40.0);
        
        final meals = await _mealService.getMealRecommendations(
          availableIngredients: availableIngredients,
          count: count,
          targetCalories: targetCalories ?? 600, // Default to 600 calories if not specified
          onProgress: (progress, message) {
            // Update the progress indicator with the received progress
            _updateProgress(progress);
          },
        );
          // Update progress - Meals retrieved (75%)
        _updateProgress(75.0);
        
        _logger.info('Received ${meals.length} meal recommendations');
        
        if (meals.isNotEmpty) {
          int realMealCount = meals.where((meal) => meal.source != MealSource.fallbackStatic).length;
          int fallbackCount = meals.where((meal) => meal.source == MealSource.fallbackStatic).length;
          int syntheticCount = meals.where((meal) => meal.source == MealSource.synthetic).length;
          
          _logger.info('Meal sources breakdown: $realMealCount from database, $syntheticCount synthetic, $fallbackCount fallbacks');
          
          // Update progress - Intermediate step (80%)
          _updateProgress(80.0);
          await Future.delayed(const Duration(milliseconds: 150));
          
          // Update progress - Processing meal data (85%)
          _updateProgress(85.0);
          
          // Small delay to ensure UI shows the progress update
          await Future.delayed(const Duration(milliseconds: 200));
          
          // Update progress - Final processing (90%)
          _updateProgress(90.0);
          await Future.delayed(const Duration(milliseconds: 150));
          
          // Add relevance score to each meal based on ingredient matching if preferredIngredients is provided
          List<Meal> updatedMeals;
          
          if (preferredIngredients != null && preferredIngredients.isNotEmpty) {
            updatedMeals = meals.map((meal) {
              final score = IngredientService.calculateIngredientMatchScore(
                meal.ingredients,
                preferredIngredients,
              );
              return meal.copyWith(relevanceScore: score);
            }).toList();
          } else {
            updatedMeals = meals;
          }
          
          // Sort meals by relevance score (highest first)
          updatedMeals.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
          
          // Add new meals to the beginning of the list
          _recommendations = [...updatedMeals, ..._recommendations];
            // Update progress - Nearly complete (95%)
          _updateProgress(95.0);
          await Future.delayed(const Duration(milliseconds: 150));
          
          // Update progress - Completing generation (100%)
          _updateProgress(100.0);
          
          // Small delay to ensure UI shows 100% progress before completing
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Check if we got any non-fallback meals
          bool hasRealMeals = updatedMeals.any((meal) => meal.source != MealSource.fallbackStatic);
          if (!hasRealMeals) {
            // Only warn if all meals are fallbacks
            _logger.warning('All generated meals are fallbacks. Ingredients may not be found in the database.');
            _logger.warning('This could be due to network connectivity issues or the OpenFoodFacts database not having matching products.');
          }
          
          return;
        } else {
          _errorMessage = 'No meals could be generated with the provided ingredients. Try a different selection.';
        }
      } else {
        _errorMessage = 'Please select at least one ingredient for meal recommendations.';
      }
    } catch (e) {
      _errorMessage = 'Error generating meal recommendations: $e';
      _logger.severe('Error generating meal recommendations: $e');
    } finally {
      _isLoading = false;
      // Make sure progress is either 100% on success or reset on error
      if (_generationProgress < 100.0) {
        _generationProgress = 0.0;
      }
      notifyListeners();
    }
  }
  
  /// Toggle favorite status of a meal
  Future<void> toggleFavorite(String mealId) async {
    final index = _recommendations.indexWhere((meal) => meal.id == mealId);
    if (index != -1) {
      final updatedMeal = _recommendations[index].copyWith(
        isFavorite: !_recommendations[index].isFavorite,
      );
      _recommendations[index] = updatedMeal;
      
      // Here we would update in storage as well when that's implemented
      // await MealService.toggleFavorite(updatedMeal);
      
      notifyListeners();
    }
  }
  
  /// Record user feedback for a meal
  Future<void> recordMealFeedback(String mealId, bool liked, {String? feedback}) async {
    // Here we would persist feedback when that's implemented
    // await MealService.recordMealFeedback(mealId, liked, feedback);
    
    // Update local state to reflect the feedback
    final index = _recommendations.indexWhere((meal) => meal.id == mealId);
    if (index != -1) {
      double scoreAdjustment = liked ? 0.2 : -0.2;
      double newScore = _recommendations[index].relevanceScore + scoreAdjustment;
      // Clamp score between 0 and 1
      newScore = newScore < 0 ? 0 : (newScore > 1 ? 1 : newScore);
      
      final updatedMeal = _recommendations[index].copyWith(relevanceScore: newScore);
      _recommendations[index] = updatedMeal;
      notifyListeners();
    }
  }
  
  /// Get favorite meals
  List<Meal> get favoriteMeals => _recommendations.where((meal) => meal.isFavorite).toList();
  
  /// Get high-relevance meals
  List<Meal> get highRelevanceMeals => 
      _recommendations.where((meal) => meal.relevanceScore > 0.7).toList();
}