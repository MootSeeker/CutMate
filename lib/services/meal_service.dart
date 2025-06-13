import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import '../models/meal.dart';
import 'openfoodfacts_service.dart';

final _logger = Logger('MealService');

class MealService {
  final OpenFoodFactsService _openFoodFactsService;

  MealService({OpenFoodFactsService? openFoodFactsService})
      : _openFoodFactsService = openFoodFactsService ?? OpenFoodFactsService();

  Future<Meal?> createAlgorithmicMeal({
    required List<String> ingredientNames,
    double? targetCalories,
    // TODO: Add other nutritional goals (protein, carbs, fat) if needed
  }) async {
    if (ingredientNames.isEmpty) {
      _logger.info('No ingredients provided, cannot create algorithmic meal.');
      return null; // Or return a random fallback meal
    }

    List<dynamic> foundProducts = [];
    List<String> missingIngredients = [];

    for (String ingredientName in ingredientNames) {
      final products = await _openFoodFactsService.searchProducts(ingredientName, pageSize: 1);
      if (products.isNotEmpty && products.first['product_name'] != null && products.first['product_name'].isNotEmpty) {
        // For simplicity, we take the first product found for each ingredient.
        // More sophisticated logic could be added here (e.g., user preference, nutritional matching).
        foundProducts.add(products.first);
        _logger.info('Found product: ${products.first['product_name']} for ingredient: $ingredientName');
      } else {
        _logger.warning('No product found for ingredient: $ingredientName');
        missingIngredients.add(ingredientName);
      }
    }

    if (foundProducts.isEmpty) {
      _logger.warning('No products found for any of the provided ingredients. Returning fallback meal.');
      return _getFallbackMeal('No products found for your ingredients.');
    }

    // Combine found products into a single meal
    String mealName = 'Meal with ${foundProducts.map((p) => p['product_name'] ?? 'Unknown Product').join(', ')}';
    if (mealName.length > 100) { // Truncate if too long
        mealName = 'Meal with ${foundProducts.length} ingredients';
    }
    if (missingIngredients.isNotEmpty) {
        mealName += ' (Missing: ${missingIngredients.join(", ")})';
    }


    String description = 'A dynamically created meal. ';
    if (missingIngredients.isNotEmpty) {
      description += 'Could not find information for: ${missingIngredients.join(', ')}. ';
    }
    description += 'Includes: ${foundProducts.map((p) => p['product_name'] ?? 'N/A').join(', ')}.';
    
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    List<String> allIngredients = [];
    List<String> allAllergens = [];
    List<String> allProductImages = []; // Track all product images

    for (var product in foundProducts) {
      // Extract nutrient information from the product
      final nutriments = product['nutriments'] ?? {};
      
      totalCalories += (nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'] ?? nutriments['energy_100g'] ?? 0).toDouble();
      totalProtein += (nutriments['proteins_100g'] ?? 0).toDouble();
      totalCarbs += (nutriments['carbohydrates_100g'] ?? 0).toDouble();
      totalFat += (nutriments['fat_100g'] ?? 0).toDouble();
      
      // Extract ingredients
      String? ingredientsText = product['ingredients_text'];
      if (ingredientsText != null && ingredientsText.isNotEmpty) {
        allIngredients.add(ingredientsText);
      } else if (product['ingredients'] != null && (product['ingredients'] as List).isNotEmpty) {
        allIngredients.addAll((product['ingredients'] as List).map((ing) => ing['text'] ?? 'unknown ingredient').cast<String>());
      }

      // Extract allergens
      if (product['allergens_tags'] != null && (product['allergens_tags'] as List).isNotEmpty) {
        allAllergens.addAll((product['allergens_tags'] as List).map((a) => a.toString().replaceAll('en:', '')).cast<String>());
      }
      
      // Collect product images - try to get the best quality image available
      final images = product['images'] ?? {};
      final selectedUrl = product['image_front_url'] ?? 
                          images['front']?['display']?['url'] ??
                          product['image_front_small_url'] ??
                          product['image_url'] ??
                          product['image'] ??
                          '';
      
      if (selectedUrl.isNotEmpty) {
        allProductImages.add(selectedUrl);
      }
    }
    
    // Deduplicate allergens and ingredients
    final uniqueIngredients = allIngredients.toSet().toList();
    final uniqueAllergens = allAllergens.toSet().toList();

    _logger.info('Calculated initial totals (sum of 100g servings): Calories: $totalCalories, Protein: $totalProtein, Carbs: $totalCarbs, Fat: $totalFat');

    double scaledCalories = totalCalories;
    double scaledProtein = totalProtein;
    double scaledCarbs = totalCarbs;
    double scaledFat = totalFat;
    double scalingFactor = 1.0;
    String mealNotes;

    if (targetCalories != null && targetCalories > 0 && totalCalories > 0) {
      scalingFactor = targetCalories / totalCalories;
      scaledCalories = totalCalories * scalingFactor;
      scaledProtein = totalProtein * scalingFactor;
      scaledCarbs = totalCarbs * scalingFactor;
      scaledFat = totalFat * scalingFactor;
      
      mealNotes = 'Nutritional values are estimated by scaling the sum of 100g servings of each product to meet your target of ${targetCalories.round()} kcal. The effective scaling factor was ${scalingFactor.toStringAsFixed(2)}.';
      _logger.info('Applied scaling factor: $scalingFactor to meet target calories: $targetCalories. Scaled Calories: $scaledCalories');
    } else if (targetCalories != null && targetCalories > 0 && totalCalories == 0) {
      mealNotes = 'Could not scale to target calories of ${targetCalories.round()} kcal because the initial combined calories of the products is zero (likely due to missing data).';
    }
    else {
      mealNotes = 'This meal was algorithmically generated by combining multiple products. Nutritional values are sums of 100g servings of each product.';
    }

    _logger.info('Created meal: $mealName with ${foundProducts.length} products.');
    
    // Create nutrients map with proper structure
    Map<String, double> nutrientsMap = {
      'calories': scaledCalories,
      'protein': scaledProtein,
      'carbs': scaledCarbs,
      'fat': scaledFat
    };
    
    List<String> dummyInstructions = ['Combine all ingredients', 'Serve and enjoy'];
    
    return Meal(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
      name: mealName,
      description: description,
      instructions: dummyInstructions, // Add basic instructions
      nutrients: nutrientsMap,
      ingredients: uniqueIngredients.isNotEmpty ? uniqueIngredients : ['Ingredient information not available for all components.'],
      imageUrl: allProductImages.isNotEmpty ? allProductImages.first : _getFallbackMeal().imageUrl, // Use the first collected image or fallback
      notes: mealNotes,
      allergenInfo: uniqueAllergens.isNotEmpty ? uniqueAllergens : ['No specific allergen information aggregated.'],
      additionalImages: allProductImages.length > 1 ? allProductImages.skip(1).take(5).toList() : [], // Include up to 5 additional product images
      tags: ['algorithmic', ...ingredientNames.map((i) => i.toLowerCase())],
      source: MealSource.algorithmicOpenFoodFacts,
      userFeedback: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      servings: foundProducts.length, // Or could be 1 combined meal
    );
  }

  Future<List<Meal>> getMealRecommendations({
    required List<String> availableIngredients,
    int count = 1,
    double? targetCalories,
  }) async {
    if (availableIngredients.isEmpty) {
      _logger.info('No ingredients for recommendations, returning fallback meals.');
      return List.generate(count, (_) => _getFallbackMeal('No ingredients provided.'));
    }

    List<Meal> meals = [];
    // For simplicity, we'll try to create one rich meal from all ingredients.
    // More advanced: try combinations, or one meal per main ingredient.
    
    Meal? meal = await createAlgorithmicMeal(
        ingredientNames: availableIngredients, 
        targetCalories: targetCalories
    );

    if (meal != null) {
      meals.add(meal);
    } else {
       _logger.warning('Algorithmic meal creation failed for ingredients: ${availableIngredients.join(", ")}. Returning fallback.');
    }

    // If not enough meals were created, fill with fallbacks
    while (meals.length < count) {
      meals.add(_getFallbackMeal('More options needed.'));
    }
    
    _logger.info('Returning ${meals.length} meal recommendations.');
    return meals.take(count).toList();
  }

  // Fallback meal if OpenFoodFacts doesn't return results or for errors
  static Meal _getFallbackMeal([String? reason]) {
    _logger.info('Providing fallback meal. Reason: ${reason ?? "Generic fallback."}');
    
    // Create nutrients map with proper structure
    Map<String, double> nutrientsMap = {
      'calories': 350.0,
      'protein': 15.0,
      'carbs': 30.0,
      'fat': 20.0
    };
    
    List<String> instructions = [
      'Wash all vegetables',
      'Chop vegetables into bite-sized pieces',
      'Mix everything in a large bowl',
      'Drizzle with olive oil and vinegar',
      'Toss well and serve immediately'
    ];
    
    return Meal(
      id: 'fallback-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Healthy Mixed Salad',
      description: reason ?? 'A delicious and nutritious mixed salad with fresh vegetables and a light vinaigrette.',
      nutrients: nutrientsMap,
      ingredients: ['Lettuce', 'Tomatoes', 'Cucumbers', 'Bell Peppers', 'Olive Oil', 'Vinegar'],
      instructions: instructions,
      preparationTime: '15 minutes',
      category: 'Salad',
      imageUrl: 'assets/images/placeholder.png', // Ensure you have a placeholder image
      notes: 'This is a sample meal. Please customize based on your preferences.',
      allergenInfo: ['None'],
      tags: ['fallback', 'healthy', 'salad', 'quick'],
      source: MealSource.fallbackStatic,
      userFeedback: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      servings: 1,
    );
  }

  // Example of a more specific fallback or a simple meal if needed elsewhere
  static Meal getSimpleFallbackMeal() {
    return _getFallbackMeal("Simple fallback requested.");
  }

  // Kept for compatibility if any UI part still uses it, but should be phased out
  // in favor of getMealRecommendations or createAlgorithmicMeal
  Future<List<Meal>> searchMeals(String query) async {
    _logger.info('Legacy searchMeals called with query: "$query". Redirecting to OpenFoodFacts product search and mapping.');
    
    // This legacy search will now try to find individual products matching the query
    // and return them as individual "meals".
    final products = await _openFoodFactsService.searchProducts(query, pageSize: 5);
    
    if (products.isEmpty) {
      _logger.warning('No products found for legacy query: "$query". Returning one fallback meal.');
      return [_getFallbackMeal('No products found for your search "$query".')];
    }

    List<Meal> meals = [];
    for (var product in products) {
      try {
        // Create nutrients map with proper structure
        Map<String, double> nutrientsMap = {};
        
        // Extract nutrient information from the product
        final nutriments = product['nutriments'] ?? {};
        
        nutrientsMap['calories'] = (nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'] ?? nutriments['energy_100g'] ?? 0).toDouble();
        nutrientsMap['protein'] = (nutriments['proteins_100g'] ?? 0).toDouble();
        nutrientsMap['carbs'] = (nutriments['carbohydrates_100g'] ?? 0).toDouble();
        nutrientsMap['fat'] = (nutriments['fat_100g'] ?? 0).toDouble();
        
        // Create simple instructions for a product
        List<String> simpleInstructions = [
            'Ready to eat product',
            'Check packaging for specific preparation instructions'
        ];
        
        // Extract ingredients
        List<String> ingredients = [];
        final ingredientsText = product['ingredients_text'];
        if (ingredientsText != null && ingredientsText.isNotEmpty) {
          ingredients = ingredientsText.split(', ');
        } else if (product['ingredients'] != null) {
          ingredients = (product['ingredients'] as List)
              .where((ing) => ing['text'] != null)
              .map((ing) => ing['text'] as String)
              .toList();
        }
        
        // Extract allergens
        List<String> allergens = [];
        if (product['allergens_tags'] != null) {
          allergens = (product['allergens_tags'] as List)
              .map((a) => a.toString().replaceAll('en:', ''))
              .toList();
        }
        
        // Extract tags
        List<String> tags = ['product'];
        if (product['brands_tags'] != null) {
          tags.addAll((product['brands_tags'] as List).map((t) => t.toString()).toList());
        }
        if (product['categories_tags'] != null) {
          tags.addAll((product['categories_tags'] as List)
              .map((c) => c.toString().replaceAll('en:', ''))
              .toList());
        }
        
        // Get image URL
        String imageUrl = product['image_front_url'] ?? 
                          product['image_front_small_url'] ?? 
                          product['image_url'] ?? 
                          product['image'] ?? 
                          'assets/images/placeholder.png';
        
        // Get category
        String category = 'General Product';
        if (product['categories_tags'] != null && (product['categories_tags'] as List).isNotEmpty) {
          category = (product['categories_tags'] as List).first.toString()
              .replaceAll('en:', '')
              .replaceAll('-', ' ');
        }
        
        final meal = Meal(
          id: product['code'] ?? 'off-${DateTime.now().millisecondsSinceEpoch}-${meals.length}',
          name: product['product_name'] ?? 'Unknown Product',
          description: product['generic_name'] ?? product['product_name'] ?? 'No description available.',
          nutrients: nutrientsMap,
          instructions: simpleInstructions,
          ingredients: ingredients.isNotEmpty ? ingredients : ['N/A'],
          preparationTime: 'N/A',
          category: category,
          imageUrl: imageUrl,
          notes: 'Data from OpenFoodFacts for 100g/100ml. Serving size may vary.',
          allergenInfo: allergens.isNotEmpty ? allergens : ['N/A'],
          tags: tags,
          source: MealSource.openFoodFactsProduct,
          userFeedback: [],
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          servings: 1, // Typically refers to 100g/ml for OFF data
        );
        meals.add(meal);
      } catch (e) {
        _logger.severe('Error creating meal from product: $e');
        // Skip this product if there's an error
      }
    }
    
    _logger.info('Legacy searchMeals mapped ${meals.length} products to meals for query "$query".');
    return meals;
  }
}

// Helper extension for nullable values, can be moved to a utility file
extension NullableSum on num? {
  num operator +(num? other) {
    if (this == null && other == null) return 0;
    if (this == null) return other!;
    if (other == null) return this!;
    return this! + other;
  }
}
