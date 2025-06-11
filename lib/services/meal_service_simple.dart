import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';
import './storage_service.dart';
import './ingredient_service.dart';

/// Simplified service for handling meal recommendations with fallback data
class MealService {
  // UUID generator
  static final _uuid = Uuid();
  
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
  }) async {
    try {
      final meals = _getFallbackMeals(mealType: mealType, availableIngredients: availableIngredients);
      
      // Save to storage for later retrieval
      _saveMealsToStorage(meals);
      
      return meals;
    } catch (e) {
      debugPrint('Error getting meal recommendations: $e');
      return _getFallbackMeals(mealType: mealType, availableIngredients: availableIngredients);
    }
  }
  
  /// Save meals to storage
  static Future<void> _saveMealsToStorage(List<Meal> meals) async {
    try {
      // Get existing meals from storage
      final existingData = await StorageService.loadData(AppConstants.mealRecommendationsKey);
      List<dynamic> existingMeals = [];
      if (existingData != null) {
        existingMeals = existingData;
      }
      
      // Add new meals to existing ones
      final mealJsonList = meals.map((meal) => meal.toJson()).toList();
      final updatedMeals = [...mealJsonList, ...existingMeals];
      
      // Limit to last 100 meals to avoid using too much storage
      final limitedMeals = updatedMeals.length > 100 
          ? updatedMeals.sublist(0, 100) 
          : updatedMeals;
      
      // Save to storage
      await StorageService.saveData(AppConstants.mealRecommendationsKey, limitedMeals);
    } catch (e) {
      debugPrint('Error saving meals to storage: $e');
    }
  }

  /// Get fallback meals for testing
  static List<Meal> _getFallbackMeals({String? mealType, List<String>? availableIngredients}) {
    final List<Meal> meals = [];
    
    if (mealType?.toLowerCase() == 'breakfast' || mealType == null) {
      meals.add(
        Meal(
          id: _uuid.v4(),
          name: 'Oatmeal with Berries',
          description: 'Classic oatmeal topped with mixed berries and honey.',
          instructions: [
            'Cook oats according to package instructions.',
            'Top with fresh or frozen berries.',
            'Drizzle with honey or maple syrup.'
          ],
          ingredients: [
            'Rolled oats',
            'Milk or water',
            'Mixed berries',
            'Honey',
          ],
          nutrients: {
            'calories': 300,
            'protein': 10,
            'carbs': 45,
            'fat': 6,
          },
          imageUrl: 'https://example.com/oatmeal.jpg',
          createdAt: DateTime.now(),
          source: 'fallback',
        ),
      );
    }
    
    if (mealType?.toLowerCase() == 'lunch' || mealType == null) {
      meals.add(
        Meal(
          id: _uuid.v4(),
          name: 'Chicken Salad Wrap',
          description: 'Healthy wrap with grilled chicken and fresh vegetables.',
          instructions: [
            'Grill chicken breast until fully cooked.',
            'Dice chicken and mix with chopped vegetables.',
            'Add light dressing and wrap in a tortilla.'
          ],
          ingredients: [
            'Chicken breast',
            'Whole wheat tortilla',
            'Mixed greens',
            'Bell pepper',
            'Light mayo or yogurt',
          ],
          nutrients: {
            'calories': 400,
            'protein': 30,
            'carbs': 35,
            'fat': 15,
          },
          imageUrl: 'https://example.com/wrap.jpg',
          createdAt: DateTime.now(),
          source: 'fallback',
        ),
      );
    }
    
    if (mealType?.toLowerCase() == 'dinner' || mealType == null) {
      meals.add(
        Meal(
          id: _uuid.v4(),
          name: 'Baked Salmon with Vegetables',
          description: 'Oven-baked salmon fillet with roasted vegetables.',
          instructions: [
            'Preheat oven to 400°F (200°C).',
            'Season salmon with salt, pepper, and lemon juice.',
            'Arrange vegetables around salmon and bake for 15-20 minutes.'
          ],
          ingredients: [
            'Salmon fillet',
            'Asparagus',
            'Cherry tomatoes',
            'Lemon',
            'Olive oil',
            'Salt and pepper',
          ],
          nutrients: {
            'calories': 450,
            'protein': 35,
            'carbs': 15,
            'fat': 25,
          },
          imageUrl: 'https://example.com/salmon.jpg',
          createdAt: DateTime.now(),
          source: 'fallback',
        ),
      );
    }
    
    if (mealType?.toLowerCase() == 'snack' || mealType == null) {
      meals.add(
        Meal(
          id: _uuid.v4(),
          name: 'Greek Yogurt with Nuts',
          description: 'Plain Greek yogurt topped with mixed nuts and a touch of honey.',
          instructions: [
            'Pour yogurt into a bowl.',
            'Top with mixed nuts and seeds.',
            'Drizzle with honey if desired.'
          ],
          ingredients: [
            'Greek yogurt',
            'Almonds',
            'Walnuts',
            'Honey (optional)',
          ],
          nutrients: {
            'calories': 200,
            'protein': 15,
            'carbs': 10,
            'fat': 12,
          },
          imageUrl: 'https://example.com/yogurt.jpg',
          createdAt: DateTime.now(),
          source: 'fallback',
        ),
      );
    }
    
    return meals;
  }
  
  /// Toggle favorite status for a meal
  static Future<Meal> toggleFavorite(Meal meal) async {
    final updatedMeal = meal.copyWith(
      isFavorite: !meal.isFavorite,
    );
    
    // Update in storage (in a real app)
    // We'd update this in a database or API
    debugPrint('Toggling favorite status for meal: ${meal.id} to ${updatedMeal.isFavorite}');
    
    return updatedMeal;
  }
  
  /// Record feedback for a meal
  static Future<void> recordMealFeedback(String mealId, bool liked, String? feedback) async {
    // In a real app, we'd send this to a database or API
    debugPrint('Recording feedback for meal: $mealId');
    debugPrint('Liked: $liked');
    if (feedback != null && feedback.isNotEmpty) {
      debugPrint('Feedback: $feedback');
    }
  }
}

