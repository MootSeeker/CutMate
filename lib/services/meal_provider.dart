import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../models/user.dart';
import '../services/meal_service.dart';

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
    
    // Try to find a recommendation with the given meal type in the name or description
    final mealTypeRegex = RegExp(mealType, caseSensitive: false);
    final matchingMeals = _recommendations.where(
      (meal) => mealTypeRegex.hasMatch(meal.name) || mealTypeRegex.hasMatch(meal.description)
    ).toList();
    
    // Return the first matching meal, or the most recent recommendation
    return matchingMeals.isNotEmpty ? matchingMeals.first : _recommendations.first;
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
  void toggleFavorite(String mealId) {
    final index = _recommendations.indexWhere((meal) => meal.id == mealId);
    if (index != -1) {
      final updatedMeal = _recommendations[index].copyWith(
        isFavorite: !_recommendations[index].isFavorite,
      );
      _recommendations[index] = updatedMeal;
      notifyListeners();
    }
  }
  
  /// Get favorite meals
  List<Meal> get favoriteMeals => 
      _recommendations.where((meal) => meal.isFavorite).toList();
}
