import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../services/meal_service_consolidated.dart'; // We'll create this consolidated file
import '../services/ingredient_service.dart';

/// Provider class for meal recommendation data
class MealProvider extends ChangeNotifier {
  List<Meal> _recommendations = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  /// All meal recommendations
  List<Meal> get recommendations => _recommendations;
  
  /// Whether meal recommendations are currently being loaded
  bool get isLoading => _isLoading;
  
  /// Error message, if any
  String get errorMessage => _errorMessage;
  
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
  
  /// Initialize the provider with data from storage
  Future<void> initialize() async {
    _recommendations = await MealService.loadMealRecommendations();
    notifyListeners();
  }
  
  /// Get new meal recommendations
  Future<void> getMealRecommendations({
    required User? user,
    int count = 1,
    List<String>? preferredIngredients,
    List<String>? availableIngredients,
    List<String>? excludedIngredients,
    Map<String, dynamic>? nutritionGoals,
    String? mealType,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final meals = await MealService.getMealRecommendations(
        user: user,
        count: count,
        preferredIngredients: preferredIngredients,
        availableIngredients: availableIngredients,
        excludedIngredients: excludedIngredients,
        nutritionGoals: nutritionGoals,
        mealType: mealType,
      );
      
      if (meals.isNotEmpty) {
        _recommendations = [...meals, ..._recommendations];
        _isLoading = false;
        notifyListeners();
      } else {
        _errorMessage = 'No meal recommendations could be generated. Please try again.';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error generating meal recommendations: $e';
      _isLoading = false;
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
      
      // Update in storage as well
      await MealService.toggleFavorite(updatedMeal);
      
      notifyListeners();
    }
  }
  
  /// Record user feedback for a meal
  Future<void> recordMealFeedback(String mealId, bool liked, {String? feedback}) async {
    await MealService.recordMealFeedback(mealId, liked, feedback);
    
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
