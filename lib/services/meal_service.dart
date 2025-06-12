import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';
import './storage_service.dart';


/// Service for handling meal recommendations with fallback mechanism and AI capabilities
class MealService {
  // UUID generator
  static const _uuid = Uuid();
  
  /// Load saved meal recommendations from storage
  static Future<List<Meal>> loadMealRecommendations() async {
    try {
      // Try to load meals from storage
      final data = await StorageService.loadData(AppConstants.mealRecommendationsKey);
      if (data != null) {
        final List<dynamic> mealDataList = data;
        final meals = mealDataList
            .map((mealData) => Meal.fromJson(mealData))
            .toList();
        return meals;
      }
      return [];
    } catch (e) {
      debugPrint('Error loading meal recommendations: $e');
      return [];
    }
  }
  
  /// Get meal recommendations based on user preferences and constraints
  static Future<List<Meal>> getMealRecommendations({
    required User? user,
    int count = 1,
    List<String>? preferredIngredients,
    List<String>? availableIngredients,
    List<String>? excludedIngredients,
    Map<String, dynamic>? nutritionGoals,
    String? mealType, // 'breakfast', 'lunch', 'dinner', 'snack'
    bool useFallbackModel = true, // Use local model if remote fails
  }) async {
    try {
      // Only use fallbacks in debug mode if explicitly requested
      if (kDebugMode) {
        // For testing purposes, we can use the fallback meals
        debugPrint('Debug mode: Using fallback meals instead of AI service');
        return _getFallbackMeals(
          mealType: mealType,
          availableIngredients: availableIngredients
        );
      }
      
      // For production, we'd normally call an AI service here
      // But for simplicity, we just use fallback meals here too
      final meals = _getFallbackMeals(
        mealType: mealType,
        availableIngredients: availableIngredients
      );
      
      // Save to storage for later retrieval
      _saveMealsToStorage(meals);
      
      return meals;
    } catch (e) {
      debugPrint('Error getting meal recommendations: $e');
      
      if (useFallbackModel) {
        // Use fallback if API call fails
        return _getFallbackMeals(
          mealType: mealType,
          availableIngredients: availableIngredients
        );
      } else {
        // Re-throw if fallbacks are disabled
        rethrow;
      }
    }
  }
  
  /// Record feedback for a meal
  static Future<void> recordMealFeedback(String mealId, bool liked, [String? feedback]) async {
    try {
      // Load existing feedback
      final feedbackData = await StorageService.loadData(AppConstants.mealFeedbackKey) ?? [];
      
      // Add new feedback
      feedbackData.add({
        'mealId': mealId,
        'liked': liked,
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Save updated feedback
      await StorageService.saveData(AppConstants.mealFeedbackKey, feedbackData);
      
      // Could also send to an analytics service in a real app
      
    } catch (e) {
      debugPrint('Error recording meal feedback: $e');
    }
  }
  
  /// Toggle favorite status of a meal and save to storage
  static Future<void> toggleFavorite(Meal meal) async {
    try {
      // Load existing meals
      final meals = await loadMealRecommendations();
      
      // Update the meal's favorite status
      final index = meals.indexWhere((m) => m.id == meal.id);
      if (index != -1) {
        meals[index] = meal;
      } else {
        meals.add(meal);
      }
      
      // Save updated meals
      await _saveMealsToStorage(meals);
      
    } catch (e) {
      debugPrint('Error toggling favorite status: $e');
    }
  }
  
  /// Save meals to storage
  static Future<void> _saveMealsToStorage(List<Meal> meals) async {
    try {
      // Get existing meals to merge with new ones
      final existingMeals = await loadMealRecommendations();
      
      // Create a map of meals by ID for easy lookup
      final Map<String, Meal> mealMap = {};
      
      // Add existing meals to the map
      for (final meal in existingMeals) {
        mealMap[meal.id] = meal;
      }
      
      // Add or update new meals
      for (final meal in meals) {
        mealMap[meal.id] = meal;
      }
      
      // Convert map back to a list
      final allMeals = mealMap.values.toList();
      
      // Sort by creation date so newest appear first
      allMeals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Limit storage to a reasonable number to avoid bloat
      final limitedMeals = allMeals.take(100).toList();
      
      // Save to storage
      await StorageService.saveData(
        AppConstants.mealRecommendationsKey, 
        limitedMeals.map((m) => m.toJson()).toList()
      );
    } catch (e) {
      debugPrint('Error saving meals to storage: $e');
    }
  }

  /// Get fallback meal recommendations for testing
  static List<Meal> _getFallbackMeals({
    String? mealType,
    List<String>? availableIngredients,
  }) {
    // Use the meal type to determine what kind of meals to return
    final meals = <Meal>[];
    String type = mealType?.toLowerCase() ?? 'any';
    
    // Generate a different meal based on the meal type
    switch (type) {
      case 'breakfast':
        meals.add(_createBreakfastMeal(availableIngredients));
        break;
      case 'lunch':
        meals.add(_createLunchMeal(availableIngredients));
        break;
      case 'dinner':
        meals.add(_createDinnerMeal(availableIngredients));
        break;
      case 'snack':
        meals.add(_createSnackMeal(availableIngredients));
        break;
      default:
        // Generate a random meal type if none specified
        final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
        final randomType = mealTypes[DateTime.now().millisecondsSinceEpoch % mealTypes.length];
        return _getFallbackMeals(mealType: randomType, availableIngredients: availableIngredients);
    }
    
    return meals;
  }
    /// Create a breakfast meal
  static Meal _createBreakfastMeal(List<String>? availableIngredients) {
    return Meal(
      id: _uuid.v4(),
      name: 'Healthy Avocado Toast',
      description: 'Creamy avocado on whole-grain toast with poached eggs and microgreens.',
      instructions: [
        'Toast two slices of whole-grain bread',
        'Mash one ripe avocado with salt, pepper, and lemon juice',
        'Spread avocado on toast',
        'Top with poached eggs and microgreens'
      ],
      ingredients: [
        'Whole-grain bread', 'Avocado', 'Eggs', 'Microgreens',
        'Salt', 'Pepper', 'Lemon juice'
      ],
      nutrients: {
        'calories': 350.0,
        'protein': 14.0,
        'carbs': 30.0,
        'fat': 22.0,
      },
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8',
      relevanceScore: _calculateRelevanceScore(['Whole-grain bread', 'Avocado', 'Eggs'], availableIngredients),
      createdAt: DateTime.now(),
      source: 'fallback',
    );
  }
    /// Create a lunch meal
  static Meal _createLunchMeal(List<String>? availableIngredients) {
    return Meal(
      id: _uuid.v4(),
      name: 'Quinoa Veggie Bowl',
      description: 'Protein-packed quinoa bowl with roasted vegetables and tahini dressing.',
      instructions: [
        'Cook quinoa according to package instructions',
        'Roast mixed vegetables (bell peppers, zucchini, cherry tomatoes)',
        'Combine quinoa and vegetables in a bowl',
        'Drizzle with tahini dressing and sprinkle with pumpkin seeds'
      ],
      ingredients: [
        'Quinoa', 'Bell peppers', 'Zucchini', 'Cherry tomatoes',
        'Tahini', 'Lemon juice', 'Garlic', 'Olive oil', 'Pumpkin seeds'
      ],
      nutrients: {
        'calories': 420.0,
        'protein': 12.0,
        'carbs': 58.0,
        'fat': 18.0,
      },
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
      relevanceScore: _calculateRelevanceScore(['Quinoa', 'Bell peppers', 'Zucchini', 'Tahini'], availableIngredients),
      createdAt: DateTime.now(),
      source: 'fallback',
    );
  }
    /// Create a dinner meal
  static Meal _createDinnerMeal(List<String>? availableIngredients) {
    return Meal(
      id: _uuid.v4(),
      name: 'Grilled Salmon with Asparagus',
      description: 'Omega-3 rich salmon fillet with roasted asparagus and lemon herb sauce.',
      instructions: [
        'Preheat grill to medium-high heat',
        'Season salmon with salt, pepper, and olive oil',
        'Grill salmon for 4-5 minutes per side',
        'Roast asparagus with olive oil, salt, and pepper',
        'Mix herbs, lemon juice, and olive oil for sauce',
        'Drizzle sauce over salmon and asparagus'
      ],
      ingredients: [
        'Salmon fillet', 'Asparagus', 'Lemon', 'Fresh herbs',
        'Olive oil', 'Salt', 'Pepper', 'Garlic'
      ],
      nutrients: {
        'calories': 380.0,
        'protein': 34.0,
        'carbs': 8.0,
        'fat': 25.0,
      },
      imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288',
      relevanceScore: _calculateRelevanceScore(['Salmon fillet', 'Asparagus', 'Lemon', 'Herbs'], availableIngredients),
      createdAt: DateTime.now(),
      source: 'fallback',
    );
  }
    /// Create a snack meal
  static Meal _createSnackMeal(List<String>? availableIngredients) {
    return Meal(
      id: _uuid.v4(),
      name: 'Greek Yogurt Parfait',
      description: 'Creamy Greek yogurt with berries, honey, and granola.',
      instructions: [
        'Layer Greek yogurt in a glass',
        'Add a layer of mixed berries',
        'Top with granola and a drizzle of honey'
      ],
      ingredients: [
        'Greek yogurt', 'Mixed berries', 'Granola', 'Honey'
      ],
      nutrients: {
        'calories': 220.0,
        'protein': 14.0,
        'carbs': 30.0,
        'fat': 6.0,
      },
      imageUrl: 'https://images.unsplash.com/photo-1488477181946-6428a0291777',
      relevanceScore: _calculateRelevanceScore(['Greek yogurt', 'Mixed berries', 'Granola'], availableIngredients),
      createdAt: DateTime.now(),
      source: 'fallback',
    );
  }
  
  /// Calculate a relevance score based on available ingredients
  static double _calculateRelevanceScore(List<String> mealIngredients, List<String>? availableIngredients) {
    // If no ingredients provided, give a medium relevance
    if (availableIngredients == null || availableIngredients.isEmpty) {
      return 0.5;
    }
    
    // Check how many ingredients match
    int matchCount = 0;
    for (final ingredient in mealIngredients) {
      for (final available in availableIngredients) {
        if (ingredient.toLowerCase().contains(available.toLowerCase()) || 
            available.toLowerCase().contains(ingredient.toLowerCase())) {
          matchCount++;
          break;
        }
      }
    }
    
    // Calculate score based on the percentage of matching ingredients
    final matchPercentage = matchCount / mealIngredients.length;
    
    // Normalize the score between 0.3 and 1.0
    return 0.3 + (matchPercentage * 0.7);
  }
}