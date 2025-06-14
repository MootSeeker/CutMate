import 'package:logging/logging.dart';
import '../models/meal.dart';
import 'openfoodfacts_service.dart';

final _logger = Logger('MealService');

class MealService {
  final OpenFoodFactsService _openFoodFactsService;

  MealService({OpenFoodFactsService? openFoodFactsService})
      : _openFoodFactsService = openFoodFactsService ?? OpenFoodFactsService();  Future<Meal?> createAlgorithmicMeal({
    required List<String> ingredientNames,
    double? targetCalories,
    Function(double progress, String message)? onProgress,
    // TODO: Add other nutritional goals (protein, carbs, fat) if needed
  }) async {
    if (ingredientNames.isEmpty) {
      _logger.info('No ingredients provided, cannot create algorithmic meal.');
      return null; // Or return a random fallback meal
    }

    _logger.info('Starting algorithmic meal creation with ingredients: ${ingredientNames.join(", ")}');
    
    List<dynamic> foundProducts = [];
    List<String> missingIngredients = [];    // Log that we're starting the ingredient search process
    _logger.info('Searching for products for ${ingredientNames.length} ingredients: ${ingredientNames.join(", ")}');
    
    // Update progress - Starting ingredient search
    onProgress?.call(50.0, 'Searching for ingredient details...');
    
    // First attempt: Try to search for specific products by ingredient name
    // We'll search with pageSize=3 to find more relevant products
    for (int i = 0; i < ingredientNames.length; i++) {
      String ingredientName = ingredientNames[i];
      bool ingredientHandled = false;
      
      // Calculate ingredient-specific progress between 50-65%
      double ingredientProgress = 50.0 + (15.0 * i / ingredientNames.length);
      onProgress?.call(ingredientProgress, 'Processing $ingredientName...');
      
      try {
        _logger.info('Searching OpenFoodFacts for ingredient: "$ingredientName"');
        
        // First try exact ingredient name
        final products = await _openFoodFactsService.searchProducts(ingredientName, pageSize: 5);
        
        if (products.isNotEmpty && products.first['product_name'] != null && products.first['product_name'].isNotEmpty) {
          // For simplicity, we take the first product found for each ingredient.
          _logger.info('✓ Found product for "$ingredientName": ${products.first['product_name']}');
          foundProducts.add(products.first);
          ingredientHandled = true;
        } else {
          _logger.warning('✗ No products found for ingredient: "$ingredientName". Will try alternative searches.');
        }
        
        // If exact name didn't work, try variations
        if (!ingredientHandled) {
          final variations = [
            'organic $ingredientName',
            '$ingredientName food',
            '$ingredientName product',
            '${ingredientName}s',
          ];
          
          for (final variation in variations) {
            if (ingredientHandled) break;
            
            _logger.info('Trying variation: "$variation"');
            final variationProducts = await _openFoodFactsService.searchProducts(variation, pageSize: 3);
            
            if (variationProducts.isNotEmpty && variationProducts.first['product_name'] != null) {
              _logger.info('✓ Found product using variation "$variation": ${variationProducts.first['product_name']}');
              foundProducts.add(variationProducts.first);
              ingredientHandled = true;
              break;
            }
          }
        }
        
        // If still not found, try generic food search
        if (!ingredientHandled) {
          // Try food databases as fallback for common ingredients
          final foodDbMap = {
            'beef': {'calories': 250, 'protein': 26, 'carbs': 0, 'fat': 17},
            'chicken': {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
            'broccoli': {'calories': 34, 'protein': 2.8, 'carbs': 7, 'fat': 0.4},
            'almonds': {'calories': 579, 'protein': 21, 'carbs': 22, 'fat': 50},
            'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3},
            'pasta': {'calories': 158, 'protein': 5.8, 'carbs': 31, 'fat': 0.9},
          };
          
          if (foodDbMap.containsKey(ingredientName.toLowerCase())) {
            // Create a synthetic product from our food database
            final nutrientInfo = foodDbMap[ingredientName.toLowerCase()]!;
            _logger.info('✓ Using built-in food data for "$ingredientName"');
            
            final syntheticProduct = {
              'product_name': 'Generic $ingredientName',
              'generic_name': 'Basic $ingredientName information',
              'code': 'synthetic-${ingredientName.toLowerCase().replaceAll(' ', '-')}',
              'ingredients_text': ingredientName,
              'categories_tags': ['en:$ingredientName', 'en:foods'],
              'image_front_url': '',
              'additional_images': <String>[],
              'nutriments': {
                'energy-kcal_100g': nutrientInfo['calories'],
                'proteins_100g': nutrientInfo['protein'],
                'carbohydrates_100g': nutrientInfo['carbs'],
                'fat_100g': nutrientInfo['fat'],
              }
            };
            
            foundProducts.add(syntheticProduct);
            ingredientHandled = true;
          }
        }
        
        // If ingredient still wasn't handled with any method, add to missing ingredients
        if (!ingredientHandled) {
          _logger.warning('✗ Failed to find any products for "$ingredientName" after all attempts');
          missingIngredients.add(ingredientName);
        }
        
      } catch (e) {
        _logger.severe('Error searching for ingredient "$ingredientName": $e');
        missingIngredients.add(ingredientName);
      }
    }
    
    // Log summary of search results
    _logger.info('Ingredient search summary: Found ${foundProducts.length} products, missing ${missingIngredients.length} ingredients');
    if (foundProducts.isNotEmpty) {
      _logger.info('Found products: ${foundProducts.map((p) => p['product_name']).join(', ')}');
    }
    if (missingIngredients.isNotEmpty) {
      _logger.info('Missing ingredients: ${missingIngredients.join(', ')}');    }    
    
    // Update progress - Analyzing search results
    onProgress?.call(65.0, 'Analyzing ingredient data...');
    
    if (foundProducts.isEmpty) {
      _logger.warning('No products found for any of the provided ingredients. Trying synthetic meal.');
      
      // Update progress - Creating synthetic meal
      onProgress?.call(70.0, 'Creating basic meal recipe...');
      
      // First attempt: create a synthetic meal if we have ingredient information
      if (ingredientNames.isNotEmpty) {
        _logger.info('Creating synthetic meal from ingredient names without OpenFoodFacts data');
        return _createSyntheticMeal(
          ingredientNames: ingredientNames,
          targetCalories: targetCalories,
          reason: 'Created from basic nutritional data. No matching products found in food database.'
        );
      }
      
      // If synthetic meal creation failed (which shouldn't happen), use fallback
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
    }    _logger.info('Created meal: $mealName with ${foundProducts.length} products.');
    
    // Update progress - Finalizing meal
    onProgress?.call(70.0, 'Finalizing recipe...');
    
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
    Function(double progress, String message)? onProgress,
  }) async {
    if (availableIngredients.isEmpty) {
      _logger.info('No ingredients for recommendations, returning fallback meals.');
      return List.generate(count, (_) => _getFallbackMeal('No ingredients provided.'));
    }

    List<Meal> meals = [];
    // For simplicity, we'll try to create one rich meal from all ingredients.
    // More advanced: try combinations, or one meal per main ingredient.
    
    // Update progress - Starting ingredient analysis
    onProgress?.call(45.0, 'Analyzing ingredients...');
    
    // Small delay to show progress update
    await Future.delayed(const Duration(milliseconds: 200));
    
    Meal? meal = await createAlgorithmicMeal(
        ingredientNames: availableIngredients, 
        targetCalories: targetCalories,
        onProgress: onProgress
    );    if (meal != null) {
      meals.add(meal);
      // Update progress - Meal created successfully
      onProgress?.call(70.0, 'Meal created successfully!');
    } else {
       _logger.warning('Algorithmic meal creation failed for ingredients: ${availableIngredients.join(", ")}. Returning fallback.');
       // Update progress - Creating fallback meal
       onProgress?.call(70.0, 'Creating alternative meal...');
    }

    // If not enough meals were created, fill with fallbacks
    while (meals.length < count) {
      meals.add(_getFallbackMeal('More options needed.'));
    }
    
    _logger.info('Returning ${meals.length} meal recommendations.');
    // Final progress update before returning
    onProgress?.call(73.0, 'Preparing recommendations...');
    
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

  /// Create a synthetic meal from ingredient names when no real products are found
  Meal _createSyntheticMeal({
    required List<String> ingredientNames,
    double? targetCalories,
    String? reason
  }) {
    _logger.info('Creating synthetic meal from ingredients: ${ingredientNames.join(", ")}');
    
    // Basic nutrition data for common ingredients (per 100g)
    final nutritionMap = {
      'beef': {'calories': 250, 'protein': 26, 'carbs': 0, 'fat': 17},
      'chicken': {'calories': 165, 'protein': 31, 'carbs': 0, 'fat': 3.6},
      'broccoli': {'calories': 34, 'protein': 2.8, 'carbs': 7, 'fat': 0.4},
      'almonds': {'calories': 576, 'protein': 21, 'carbs': 22, 'fat': 49},
      'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3},
      'pasta': {'calories': 158, 'protein': 5.8, 'carbs': 31, 'fat': 0.9},
      'eggs': {'calories': 143, 'protein': 13, 'carbs': 1.1, 'fat': 9.5},
      'spinach': {'calories': 23, 'protein': 2.9, 'carbs': 3.6, 'fat': 0.4},
      'tomatoes': {'calories': 18, 'protein': 0.9, 'carbs': 3.9, 'fat': 0.2},
      'potatoes': {'calories': 77, 'protein': 2.0, 'carbs': 17, 'fat': 0.1},
      'onions': {'calories': 40, 'protein': 1.1, 'carbs': 9.3, 'fat': 0.1},
      'garlic': {'calories': 149, 'protein': 6.4, 'carbs': 33, 'fat': 0.5},
      'olive oil': {'calories': 884, 'protein': 0, 'carbs': 0, 'fat': 100},
      'cheese': {'calories': 350, 'protein': 25, 'carbs': 1.3, 'fat': 28},
      'greek yogurt': {'calories': 59, 'protein': 10, 'carbs': 3.6, 'fat': 0.4},
      'beans': {'calories': 347, 'protein': 21, 'carbs': 63, 'fat': 1.2},
      'lentils': {'calories': 116, 'protein': 9, 'carbs': 20, 'fat': 0.4},
      'quinoa': {'calories': 120, 'protein': 4.4, 'carbs': 21, 'fat': 1.9},
      'avocado': {'calories': 160, 'protein': 2, 'carbs': 8.5, 'fat': 15},
      'fish': {'calories': 206, 'protein': 22, 'carbs': 0, 'fat': 12},
    };
    
    // Calculate basic nutrition totals
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
      // Use a standard portion of each ingredient (80g)
    const portionSize = 80.0; // grams
    const portionFactor = portionSize / 100.0; // nutritional data is per 100g
    
    // Calculate nutrition from ingredients
    for (String ingredient in ingredientNames) {
      final normalizedIngredient = ingredient.toLowerCase();
      if (nutritionMap.containsKey(normalizedIngredient)) {
        final nutrition = nutritionMap[normalizedIngredient]!;
        totalCalories += (nutrition['calories'] as double) * portionFactor;
        totalProtein += (nutrition['protein'] as double) * portionFactor;
        totalCarbs += (nutrition['carbs'] as double) * portionFactor;
        totalFat += (nutrition['fat'] as double) * portionFactor;
        _logger.info('Added synthetic data for $ingredient: ${nutrition['calories']} kcal/100g');
      } else {
        // For unknown ingredients, use a standard estimate
        totalCalories += 100 * portionFactor; // Assume 100 kcal per 100g
        totalProtein += 5 * portionFactor;   // Assume 5g protein per 100g
        totalCarbs += 10 * portionFactor;    // Assume 10g carbs per 100g
        totalFat += 3 * portionFactor;       // Assume 3g fat per 100g
        _logger.info('Used default nutritional estimate for unknown ingredient: $ingredient');
      }
    }
    
    double scalingFactor = 1.0;
    if (targetCalories != null && targetCalories > 0 && totalCalories > 0) {
      scalingFactor = targetCalories / totalCalories;
      totalCalories = totalCalories * scalingFactor;
      totalProtein = totalProtein * scalingFactor;
      totalCarbs = totalCarbs * scalingFactor;
      totalFat = totalFat * scalingFactor;
    }
    
    // Create meal name
    String mealName;
    if (ingredientNames.length <= 3) {      mealName = "${ingredientNames.join(", ")} ${_getMealType(ingredientNames)}";
    } else {
      mealName = "${ingredientNames[0]} and ${ingredientNames[1]} ${_getMealType(ingredientNames)}";
    }
    
    // Generate simple instructions based on ingredients
    List<String> instructions = _generateInstructions(ingredientNames);
    
    // Create nutrient map
    Map<String, double> nutrientsMap = {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat
    };
    
    final notes = reason ?? 'This meal was created from basic ingredient data. Nutrition values are estimates.';
    
    return Meal(
      id: 'synthetic-${DateTime.now().millisecondsSinceEpoch}',
      name: mealName,
      description: 'A meal featuring ${ingredientNames.join(", ")}.',
      nutrients: nutrientsMap,
      ingredients: ingredientNames,      instructions: instructions,
      imageUrl: 'assets/images/placeholder.png', // Local asset path that will be properly handled
      notes: '$notes Nutrition values are estimates based on standard portions.',
      allergenInfo: ['No allergen information available'],
      tags: ['synthetic', ...ingredientNames.map((i) => i.toLowerCase())],
      source: MealSource.synthetic,
      userFeedback: [],
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      servings: ingredientNames.length > 1 ? 2 : 1,
    );
  }
  
  /// Helper to generate a reasonable meal type based on ingredients
  String _getMealType(List<String> ingredients) {
    // Convert ingredients to lowercase for easier matching
    final lowerIngredients = ingredients.map((i) => i.toLowerCase()).toList();
    
    // Check for breakfast ingredients
    if (lowerIngredients.contains('eggs') || 
        lowerIngredients.contains('yogurt') || 
        lowerIngredients.contains('greek yogurt') ||
        lowerIngredients.contains('avocado') && lowerIngredients.contains('toast')) {
      return 'Breakfast';
    }
    
    // Check for salad ingredients
    if (lowerIngredients.contains('lettuce') || 
        (lowerIngredients.contains('spinach') && !lowerIngredients.contains('pasta'))) {
      return 'Salad';
    }
    
    // Check for pasta dishes
    if (lowerIngredients.contains('pasta') || 
        lowerIngredients.contains('spaghetti') ||
        lowerIngredients.contains('penne')) {
      return 'Pasta';
    }
    
    // Check for rice dishes
    if (lowerIngredients.contains('rice')) {
      return 'Bowl';
    }
    
    // Check for meat-based dishes
    if (lowerIngredients.contains('beef') || 
        lowerIngredients.contains('chicken') ||
        lowerIngredients.contains('pork')) {
      if (lowerIngredients.contains('broccoli') || 
          lowerIngredients.contains('spinach') ||
          lowerIngredients.contains('vegetables')) {
        return 'Stir-fry';
      }
      return 'Dish';
    }
    
    // Default dish name
    return 'Meal';
  }
  
  /// Generate simple cooking instructions based on ingredients
  List<String> _generateInstructions(List<String> ingredients) {
    final lowerIngredients = ingredients.map((i) => i.toLowerCase()).toList();
    List<String> instructions = [];
    
    // Preparation steps
    instructions.add('Gather all ingredients and prepare your workspace.');
    
    // Washing step for vegetables
    if (lowerIngredients.any((i) => 
        ['broccoli', 'spinach', 'lettuce', 'tomatoes', 'vegetables'].contains(i))) {
      instructions.add('Wash all vegetables thoroughly.');
    }
    
    // Chopping step
    instructions.add('Chop all ingredients into appropriately sized pieces.');
    
    // Cooking step based on ingredients
    if (lowerIngredients.contains('beef') || 
        lowerIngredients.contains('chicken') || 
        lowerIngredients.contains('pork') ||
        lowerIngredients.contains('fish')) {
      instructions.add('Cook the protein in a pan until done to your liking.');
      
      if (lowerIngredients.any((i) => 
          ['broccoli', 'spinach', 'onions', 'garlic', 'vegetables'].contains(i))) {
        instructions.add('Sauté the vegetables in the same pan.');
      }
    } else if (lowerIngredients.contains('pasta') || lowerIngredients.contains('rice')) {
      instructions.add('Cook the ${lowerIngredients.contains("pasta") ? "pasta" : "rice"} according to package instructions.');
    }
    
    // Combining step
    instructions.add('Combine all ingredients in a bowl or plate.');
    
    // Dressing/seasoning step
    if (lowerIngredients.contains('olive oil')) {
      instructions.add('Drizzle with olive oil and season to taste.');
    } else {
      instructions.add('Season with salt and pepper to taste.');
    }
    
    // Serving step
    instructions.add('Serve immediately and enjoy!');
    
    return instructions;
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
