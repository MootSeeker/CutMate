import 'package:flutter/foundation.dart';

/// Service for ingredient matching and scoring
class IngredientService {
  /// Common ingredient substitutions that can be used in recipes
  static const Map<String, List<String>> _substitutions = {
    'chicken': ['turkey', 'tofu', 'chickpeas', 'tempeh'],
    'beef': ['turkey', 'bison', 'mushrooms', 'lentils', 'bean'],
    'pork': ['chicken', 'turkey', 'tofu', 'tempeh'],
    'fish': ['tofu', 'tempeh', 'chickpeas'],
    'milk': ['almond milk', 'soy milk', 'oat milk', 'coconut milk'],
    'cheese': ['nutritional yeast', 'tofu', 'cashew cheese', 'vegan cheese'],
    'butter': ['olive oil', 'coconut oil', 'avocado', 'nut butter'],
    'eggs': ['flax seeds', 'chia seeds', 'tofu', 'applesauce', 'banana'],
    'flour': ['almond flour', 'coconut flour', 'oat flour', 'rice flour'],
    'sugar': ['honey', 'maple syrup', 'stevia', 'coconut sugar', 'monk fruit'],
    'rice': ['quinoa', 'cauliflower rice', 'barley', 'bulgur', 'couscous'],
    'pasta': ['zucchini noodles', 'spaghetti squash', 'rice noodles', 'shirataki noodles'],
    'potatoes': ['sweet potatoes', 'cauliflower', 'turnips', 'parsnips'],
    'mayonnaise': ['greek yogurt', 'avocado', 'hummus'],
    'bread': ['lettuce wraps', 'tortilla', 'flatbread', 'pita'],
    'nuts': ['seeds', 'beans', 'peas', 'lentils'],
    'chocolate': ['carob', 'cocoa powder', 'cacao nibs'],
  };
  
  /// Categories of ingredients - useful for grouping similar ingredients
  static const Map<String, List<String>> _categories = {
    'protein': ['chicken', 'beef', 'pork', 'fish', 'tofu', 'tempeh', 'eggs', 'yogurt', 'cottage cheese', 'protein powder'],
    'vegetable': ['spinach', 'kale', 'broccoli', 'cauliflower', 'carrots', 'peppers', 'onions', 'garlic', 'tomatoes', 'zucchini'],
    'fruit': ['apples', 'bananas', 'berries', 'oranges', 'grapes', 'pears', 'melon', 'pineapple', 'mango', 'avocado'],
    'grain': ['rice', 'quinoa', 'oats', 'bread', 'pasta', 'barley', 'bulgur', 'couscous'],
    'dairy': ['milk', 'cheese', 'yogurt', 'butter', 'cream', 'cottage cheese'],
    'fat': ['olive oil', 'coconut oil', 'avocado oil', 'butter', 'ghee', 'nuts', 'seeds'],
    'herb': ['basil', 'cilantro', 'parsley', 'mint', 'rosemary', 'thyme', 'oregano', 'sage'],
    'spice': ['salt', 'pepper', 'cumin', 'paprika', 'turmeric', 'cinnamon', 'nutmeg', 'ginger'],
  };

  /// Calculate ingredient match score between user ingredients and recipe ingredients
  /// Returns a score from 0 (no match) to 1 (perfect match)
  static double calculateIngredientMatchScore(
    List<String> recipeIngredients, 
    List<String>? userIngredients,
  ) {
    if (userIngredients == null || userIngredients.isEmpty) {
      return 0.0;
    }
    
    // Normalize ingredient lists for case-insensitive comparison
    final normalizedRecipeIngredients = _normalizeIngredientList(recipeIngredients);
    final normalizedUserIngredients = _normalizeIngredientList(userIngredients);    // Count how many user ingredients or their substitutes are found in the recipe
    double matchCount = 0;
    int totalIngredientWordsInRecipe = 0;
    
    // Calculate how many ingredients contain user's available ingredients
    for (final recipeIngredient in normalizedRecipeIngredients) {
      totalIngredientWordsInRecipe++;
      
      // Check direct matches
      for (final userIngredient in normalizedUserIngredients) {
        if (_isIngredientMatch(recipeIngredient, userIngredient)) {
          matchCount++;
          break;
        }
        
        // Check substitution matches
        if (_canSubstituteIngredient(recipeIngredient, userIngredient)) {
          matchCount += 0.7; // Substitutes are not perfect matches
          break;
        }
      }
    }
      // Calculate additional score for recipe efficiency (uses higher % of provided ingredients)
    double userIngredientsUsed = 0;
    for (final userIngredient in normalizedUserIngredients) {
      for (final recipeIngredient in normalizedRecipeIngredients) {
        if (_isIngredientMatch(recipeIngredient, userIngredient) || 
            _canSubstituteIngredient(recipeIngredient, userIngredient)) {
          userIngredientsUsed++;
          break;
        }
      }
    }
    
    // Final score calculation: 
    // 50% based on recipe ingredients matched
    // 50% based on percentage of user ingredients used
    double recipeMatchRatio = totalIngredientWordsInRecipe > 0 
        ? matchCount / totalIngredientWordsInRecipe 
        : 0.0;
    
    double userIngredientUsageRatio = normalizedUserIngredients.isNotEmpty 
        ? userIngredientsUsed / normalizedUserIngredients.length 
        : 0.0;
    
    return (recipeMatchRatio * 0.5) + (userIngredientUsageRatio * 0.5);
  }

  /// Check if a recipe ingredient contains a user ingredient
  static bool _isIngredientMatch(String recipeIngredient, String userIngredient) {
    return recipeIngredient.contains(userIngredient);
  }
  
  /// Check if we can substitute a recipe ingredient with a user ingredient
  static bool _canSubstituteIngredient(String recipeIngredient, String userIngredient) {
    // Find the base ingredient in the recipe (remove quantities and units)
    String baseRecipeIngredient = _extractBaseIngredient(recipeIngredient);
    
    // Check if we have substitutions for this ingredient
    for (final entry in _substitutions.entries) {
      // If the recipe calls for an ingredient we have substitutions for
      if (baseRecipeIngredient.contains(entry.key)) {
        // Check if the user has one of the valid substitutes
        for (final substitute in entry.value) {
          if (userIngredient.contains(substitute)) {
            return true;
          }
        }
      }
      
      // Check the opposite direction - if user ingredient can substitute for recipe
      if (userIngredient.contains(entry.key)) {
        for (final substitute in entry.value) {
          if (baseRecipeIngredient.contains(substitute)) {
            return true;
          }
        }
      }
    }
    
    return false;
  }
  
  /// Extract the base ingredient from a recipe ingredient string
  /// e.g. "1 cup diced onions" -> "onions"
  static String _extractBaseIngredient(String ingredient) {
    // This is a simplistic implementation
    // Remove common units and quantities
    final units = ['cup', 'tablespoon', 'teaspoon', 'tbsp', 'tsp', 'ounce', 'oz', 'pound', 'lb', 'g', 'kg', 'ml', 'l'];
    final quantities = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '½', '¼', '¾', 'half', 'quarter'];
    final states = ['diced', 'chopped', 'minced', 'sliced', 'grated', 'shredded', 'ground', 'cooked'];
    
    String cleaned = ingredient.toLowerCase();
    
    for (final unit in units) {
      cleaned = cleaned.replaceAll(unit, '');
    }
    
    for (final quantity in quantities) {
      cleaned = cleaned.replaceAll(quantity, '');
    }
    
    for (final state in states) {
      cleaned = cleaned.replaceAll(state, '');
    }
    
    // Remove special characters and extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    
    return cleaned;
  }
  
  /// Normalize an ingredient list for better matching
  static List<String> _normalizeIngredientList(List<String> ingredients) {
    return ingredients.map((i) => i.toLowerCase().trim()).toList();
  }
  
  /// Identify the primary protein ingredient in a meal
  static String? identifyPrimaryProtein(List<String> ingredients) {
    for (final ingredient in ingredients) {
      final normalized = ingredient.toLowerCase();
      for (final protein in _categories['protein'] ?? []) {
        if (normalized.contains(protein)) {
          return protein;
        }
      }
    }
    return null;
  }
  
  /// Identify the primary vegetable in a meal
  static String? identifyPrimaryVegetable(List<String> ingredients) {
    for (final ingredient in ingredients) {
      final normalized = ingredient.toLowerCase();
      for (final vegetable in _categories['vegetable'] ?? []) {
        if (normalized.contains(vegetable)) {
          return vegetable;
        }
      }
    }
    return null;
  }
}
