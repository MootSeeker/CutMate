import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final _logger = Logger('OpenFoodFactsService');

/// Service to interact with OpenFoodFacts API for food and nutrition data
class OpenFoodFactsService {  // OpenFoodFacts API base URL
  final String _searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  
  // Initialize OpenFoodFacts client
  OpenFoodFactsService() {
    _initializeOpenFoodFacts();
    // Check connectivity on initialization
    _checkApiConnectivity();
  }
  
  /// Check if we can connect to the OpenFoodFacts API
  Future<bool> _checkApiConnectivity() async {
    try {
      _logger.info('Checking connectivity to OpenFoodFacts API...');
      final testUri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/737628064502.json');
      
      final response = await http.get(testUri, headers: {
        'User-Agent': 'CutMate/1.0 (Flutter; +https://example.com)',
      }).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        _logger.info('Successfully connected to OpenFoodFacts API. Status: ${response.statusCode}');
        return true;
      } else {
        _logger.warning('Could not connect to OpenFoodFacts API. Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.severe('Error checking API connectivity: $e');
      return false;
    }
  }
  
  void _initializeOpenFoodFacts() {
    try {
      OpenFoodAPIConfiguration.userAgent = UserAgent(
        name: 'CutMate - Meal Planner',
        version: '1.0',
        system: 'Android/iOS/Web',
      );
      _logger.info('OpenFoodFacts API client initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize OpenFoodFacts API client: $e');
    }  }

  /// Return fallback product data for when API access fails
  List<Map<String, dynamic>> _getFallbackProducts(String query) {
    _logger.info('Providing fallback data for query: "$query"');
    
    // Map common ingredients to basic nutritional data
    final fallbackData = {
      'beef': {
        'product_name': 'Ground Beef',
        'generic_name': 'Beef product',
        'code': 'fallback-beef',
        'nutriments': {
          'energy-kcal_100g': 250.0,
          'proteins_100g': 26.0,
          'carbohydrates_100g': 0.0,
          'fat_100g': 17.0
        },
        'ingredients_text': 'Ground beef',
        'categories_tags': ['en:meats', 'en:beef'],
        'brands_tags': ['generic'],
        'image_front_url': '',
        'additional_images': []
      },
      'broccoli': {
        'product_name': 'Fresh Broccoli',
        'generic_name': 'Broccoli',
        'code': 'fallback-broccoli',
        'nutriments': {
          'energy-kcal_100g': 34.0,
          'proteins_100g': 2.8,
          'carbohydrates_100g': 7.0,
          'fat_100g': 0.4
        },
        'ingredients_text': 'Broccoli',
        'categories_tags': ['en:vegetables', 'en:broccoli'],
        'brands_tags': ['generic'],
        'image_front_url': '',
        'additional_images': []
      },
      'almonds': {
        'product_name': 'Raw Almonds',
        'generic_name': 'Almonds',
        'code': 'fallback-almonds',
        'nutriments': {
          'energy-kcal_100g': 579.0,
          'proteins_100g': 21.0,
          'carbohydrates_100g': 22.0,
          'fat_100g': 50.0
        },
        'ingredients_text': 'Almonds',
        'categories_tags': ['en:nuts', 'en:almonds'],
        'brands_tags': ['generic'],
        'image_front_url': '',
        'additional_images': []
      }
    };
    
    // Try to match the query to a fallback product
    final normalizedQuery = query.toLowerCase().trim();
    
    // If we have a direct match, return it
    if (fallbackData.containsKey(normalizedQuery)) {
      return [fallbackData[normalizedQuery]!];
    }
    
    // If no direct match, use a generic template
    return [{
      'product_name': 'Generic ${query.substring(0, 1).toUpperCase() + query.substring(1)}',
      'generic_name': 'Basic food item',
      'code': 'fallback-generic-${normalizedQuery.replaceAll(' ', '-')}',
      'nutriments': {
        'energy-kcal_100g': 100.0,
        'proteins_100g': 5.0,
        'carbohydrates_100g': 10.0,
        'fat_100g': 2.0
      },
      'ingredients_text': query,
      'categories_tags': ['en:foods'],
      'brands_tags': ['generic'],
      'image_front_url': '',
      'additional_images': []
    }];
  }

  /// Search for products by name or keyword using both SDK and direct API access if needed
  Future<List<Map<String, dynamic>>> searchProducts(String query, {int pageSize = 10}) async {
    _logger.info('Searching for products with query: "$query", pageSize: $pageSize');
    
    try {
      // Check connectivity first
      bool isConnected = await _checkApiConnectivity();
      if (!isConnected) {
        _logger.warning('Cannot connect to OpenFoodFacts API. Using fallback static data.');
        return _getFallbackProducts(query);
      }
      
      // Try direct API call first (more reliable for ingredient searches)
      _logger.info('Trying direct API call for "$query"');
      final directResults = await _searchWithDirectApi(query, pageSize: pageSize);
      
      if (directResults.isNotEmpty) {
        _logger.info('Direct API search successful, found ${directResults.length} products');
        return directResults;
      }
      
      // If direct API fails, try SDK
      _logger.info('Direct API returned no results, trying SDK');
      final sdkResults = await _searchWithSdk(query, pageSize: pageSize);
      
      if (sdkResults.isNotEmpty) {
        _logger.info('SDK search successful, found ${sdkResults.length} products');
        return sdkResults;
      }
      
      _logger.warning('Both direct API and SDK searches failed to find products for "$query"');
      return _getFallbackProducts(query);
    } catch (e, stackTrace) {
      _logger.severe('Error searching for products: $e\n$stackTrace');
      return _getFallbackProducts(query);
    }
  }
  
  /// Search using direct HTTP request to the OpenFoodFacts API
  Future<List<Map<String, dynamic>>> _searchWithDirectApi(String query, {int pageSize = 10}) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();
      
      // Built alternative queries
      final List<String> searchQueries = _buildAlternativeQueries(normalizedQuery);
      List<Map<String, dynamic>> allResults = [];
      
      // Try each query until we find results or exhaust all options
      for (final searchQuery in searchQueries) {
        if (allResults.length >= pageSize) break;
        
        _logger.info('Trying direct API query: "$searchQuery"');
        
        // Build request URL
        final uri = Uri.parse(_searchUrl).replace(queryParameters: {
          'search_terms': searchQuery,
          'page_size': pageSize.toString(),
          'json': '1',
          'action': 'process',
          'fields': 'product_name,generic_name,image_url,image_front_url,image_ingredients_url,image_nutrition_url,ingredients_text,nutriments,categories_tags,brands_tags,allergens_tags',
        });
        
        // Log full URL for debugging
        _logger.info('Direct API request URL: ${uri.toString()}');
        
        final response = await http.get(uri, headers: {
          'User-Agent': 'CutMate/1.0 (Flutter; +https://example.com)',
        });
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          
          if (data.containsKey('products') && data['products'] is List && data['products'].isNotEmpty) {
            List<dynamic> products = data['products'];
            _logger.info('Direct API found ${products.length} products for "$searchQuery"');
            
            // Process each product
            for (var product in products) {
              if (product is Map<String, dynamic>) {
                try {
                  final processedProduct = _processDirectApiProduct(product);
                  allResults.add(processedProduct);
                  
                  _logger.info('Added product: ${processedProduct['product_name']}');
                } catch (e) {
                  _logger.warning('Error processing direct API product: $e');
                }
              }
            }
          } else {
            _logger.warning('Direct API returned no products for "$searchQuery"');
          }
        } else {
          _logger.warning('Direct API request failed with status code: ${response.statusCode}');
        }
      }
      
      return allResults.take(pageSize).toList();
    } catch (e) {
      _logger.severe('Error in direct API search: $e');
      return [];
    }
  }
  
  /// Process a product from the direct API response
  Map<String, dynamic> _processDirectApiProduct(Map<String, dynamic> apiProduct) {
    final Map<String, dynamic> processedProduct = {
      'product_name': apiProduct['product_name'] ?? 'Unknown Product',
      'generic_name': apiProduct['generic_name'] ?? '',
      'code': apiProduct['code'] ?? '',
      'ingredients_text': apiProduct['ingredients_text'] ?? '',
      'categories_tags': apiProduct['categories_tags'] ?? [],
      'brands_tags': apiProduct['brands_tags'] ?? [],
      'additional_images': <String>[],
    };
    
    // Process images
    processedProduct['image_front_url'] = apiProduct['image_front_url'] ?? 
                                          apiProduct['image_url'] ?? 
                                          '';
    
    // Additional images
    List<String> additionalImages = [];
    if (apiProduct['image_ingredients_url'] != null && apiProduct['image_ingredients_url'].toString().isNotEmpty) {
      additionalImages.add(apiProduct['image_ingredients_url']);
    }
    if (apiProduct['image_nutrition_url'] != null && apiProduct['image_nutrition_url'].toString().isNotEmpty) {
      additionalImages.add(apiProduct['image_nutrition_url']);
    }
    processedProduct['additional_images'] = additionalImages;
      // Process nutrients
    Map<String, dynamic> nutriments = {
      'energy-kcal_100g': 0.0,
      'proteins_100g': 0.0,
      'carbohydrates_100g': 0.0,
      'fat_100g': 0.0
    };
    
    if (apiProduct['nutriments'] != null && apiProduct['nutriments'] is Map) {
      final nutrientsData = apiProduct['nutriments'];
      
      // Handle energy values with fallback logic
      if (nutrientsData['energy-kcal_100g'] != null) {
        nutriments['energy-kcal_100g'] = _parseDouble(nutrientsData['energy-kcal_100g']);
      } else if (nutrientsData['energy-kcal'] != null) {
        nutriments['energy-kcal_100g'] = _parseDouble(nutrientsData['energy-kcal']);
      } else if (nutrientsData['energy_100g'] != null) {
        // Convert kJ to kcal if needed (approximate)
        nutriments['energy-kcal_100g'] = _parseDouble(nutrientsData['energy_100g']) / 4.184;
      }
      
      // Get other nutrient values
      if (nutrientsData['proteins_100g'] != null) {
        nutriments['proteins_100g'] = _parseDouble(nutrientsData['proteins_100g']);
      }
      
      if (nutrientsData['carbohydrates_100g'] != null) {
        nutriments['carbohydrates_100g'] = _parseDouble(nutrientsData['carbohydrates_100g']);
      }
      
      if (nutrientsData['fat_100g'] != null) {
        nutriments['fat_100g'] = _parseDouble(nutrientsData['fat_100g']);
      }
    }
    
    processedProduct['nutriments'] = nutriments;
    return processedProduct;
  }
  
  /// Build a list of alternative queries for the same ingredient
  List<String> _buildAlternativeQueries(String query) {
    List<String> queries = [query]; // Start with the original query
    
    // Specific alternatives for common ingredients
    final alternativesMap = {
      'beef': ['fresh beef', 'beef meat', 'ground beef', 'beef steak', 'beef product'],
      'chicken': ['chicken meat', 'chicken breast', 'chicken thigh', 'chicken product'],
      'broccoli': ['fresh broccoli', 'broccoli florets', 'organic broccoli', 'broccoli frozen'],
      'almonds': ['raw almonds', 'almond nuts', 'whole almonds', 'almond product'],
      'eggs': ['chicken eggs', 'large eggs', 'egg product'],
    };
    
    if (alternativesMap.containsKey(query)) {
      queries.addAll(alternativesMap[query]!);
    } else {
      // Generic alternatives
      queries.add('organic $query');
      queries.add('$query product');
      queries.add('$query food');
    }
    
    return queries;
  }
  
  /// Search using the OpenFoodFacts SDK
  Future<List<Map<String, dynamic>>> _searchWithSdk(String query, {int pageSize = 10}) async {
    try {
      // Debug log to check OpenFoodFacts API status
      OpenFoodFactsLanguage? englishLanguage;
      try {
        englishLanguage = OpenFoodFactsLanguage.ENGLISH;
        _logger.info('OpenFoodFacts language initialized successfully');
      } catch (e) {
        _logger.severe('Error initializing OpenFoodFacts language: $e');
        // Fallback
        englishLanguage = OpenFoodFactsLanguage.ENGLISH;
      }
      
      // Normalize search query to improve matches
      final normalizedQuery = query.toLowerCase().trim();
      _logger.info('Normalized search query: $normalizedQuery');
        // Try ingredient category approach - lookup based on general category
      // This improves search results for generic ingredients like "beef" or "broccoli"
      final categoryMap = {
        'beef': ['fresh beef', 'beef meat', 'ground beef'],
        'chicken': ['chicken meat', 'chicken breast', 'chicken thigh'],
        'broccoli': ['fresh broccoli', 'broccoli florets', 'organic broccoli'],
        'fish': ['fresh fish', 'salmon', 'tuna'],
        'rice': ['cooked rice', 'white rice', 'brown rice'],
        'pasta': ['pasta', 'spaghetti', 'penne'],
        'eggs': ['chicken eggs', 'large eggs', 'organic eggs'],
        'milk': ['cow milk', 'whole milk', '2% milk'],
        'almonds': ['raw almonds', 'almond', 'almond nuts'],
        'quinoa': ['organic quinoa', 'white quinoa', 'quinoa grain'],
        'avocado': ['fresh avocado', 'hass avocado', 'avocado fruit'],
        'beans': ['black beans', 'kidney beans', 'pinto beans'],
        'lentils': ['red lentils', 'green lentils', 'brown lentils'],
        'spinach': ['fresh spinach', 'baby spinach', 'organic spinach'],
        'tomatoes': ['fresh tomatoes', 'roma tomatoes', 'cherry tomatoes'],
        'onions': ['yellow onions', 'red onions', 'white onions'],
        'garlic': ['fresh garlic', 'garlic cloves', 'minced garlic'],
        'potatoes': ['russet potatoes', 'red potatoes', 'gold potatoes'],
        'cheese': ['cheddar cheese', 'Swiss cheese', 'mozzarella cheese'],
        'greek yogurt': ['plain greek yogurt', 'vanilla greek yogurt', 'nonfat greek yogurt'],
      };
      
      // Get the array of search terms for this ingredient or create a single-element array with the normalized query
      final searchTerms = categoryMap[normalizedQuery] ?? [normalizedQuery];
      
      // Use the best match (first in the array) as the enhanced query
      final enhancedQuery = searchTerms[0];
      _logger.info('Enhanced search query: $enhancedQuery (from list: ${searchTerms.join(', ')})');
      
      // Create the SearchTerms parameter using the primary enhanced query
      final parameter = SearchTerms(terms: [enhancedQuery]);
      
      // Set a higher page size to increase chances of finding relevant products
      final pageSizeParam = PageSize(size: pageSize > 1 ? pageSize : 5); // Use at least 5 results to improve chances
      
      final configuration = ProductSearchQueryConfiguration(
        parametersList: [parameter, pageSizeParam],
        language: englishLanguage,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );      _logger.info('Sending request to OpenFoodFacts API for query: $enhancedQuery');
      final result = await OpenFoodAPIClient.searchProducts(
        const User(userId: '', password: ''),
        configuration,
      );
      
      if (result.products != null && result.products!.isNotEmpty) {
        _logger.info('Found ${result.products!.length} products for query: "$enhancedQuery"');
        
        // Log product names for debugging
        for (var product in result.products!) {
          _logger.info('Product found: ${product.productName ?? "Unknown"} (${product.barcode})');
        }
        
        // Convert Product objects to Maps for easier processing
        List<Map<String, dynamic>> productMaps = [];
        
        for (var product in result.products!) {
          try {
            // Create a map with basic product details
            final Map<String, dynamic> productMap = {
              'product_name': product.productName ?? 'Unknown Product',
              'generic_name': product.genericName ?? '',
              'code': product.barcode ?? '',
              'nutriments': {},
              'ingredients_text': product.ingredientsText ?? '',
              'categories_tags': product.categoriesTags ?? [],
              'brands_tags': product.brandsTags ?? [],
            };
            
            // Handle images
            if (product.imageFrontUrl != null && product.imageFrontUrl!.isNotEmpty) {
              productMap['image_front_url'] = product.imageFrontUrl;
            } else if (product.imageFrontSmallUrl != null && product.imageFrontSmallUrl!.isNotEmpty) {
              productMap['image_front_url'] = product.imageFrontSmallUrl;
            } else {
              productMap['image_front_url'] = '';
            }
            
            // Use additional images when available
            List<String> additionalImages = [];
            if (product.imageIngredientsUrl != null && product.imageIngredientsUrl!.isNotEmpty) {
              additionalImages.add(product.imageIngredientsUrl!);
            }
            if (product.imageNutritionUrl != null && product.imageNutritionUrl!.isNotEmpty) {
              additionalImages.add(product.imageNutritionUrl!);
            }
            if (product.imagePackagingUrl != null && product.imagePackagingUrl!.isNotEmpty) {
              additionalImages.add(product.imagePackagingUrl!);
            }
            productMap['additional_images'] = additionalImages;
            
            // Handle nutrients manually - OpenFoodFacts values can be deeply nested or null
            Map<String, dynamic> nutriments = {
              'energy-kcal_100g': 0.0,
              'proteins_100g': 0.0,
              'carbohydrates_100g': 0.0,
              'fat_100g': 0.0
            };
            
            try {
              if (product.nutriments != null) {
                // Access the raw JSON map to safely extract values
                final nutrientsMap = product.nutriments!.toJson();
                
                if (nutrientsMap.containsKey('energy-kcal_100g')) {
                  nutriments['energy-kcal_100g'] = _parseDouble(nutrientsMap['energy-kcal_100g']);
                } else if (nutrientsMap.containsKey('energy-kcal')) {
                  nutriments['energy-kcal_100g'] = _parseDouble(nutrientsMap['energy-kcal']);
                } else if (nutrientsMap.containsKey('energy_100g')) {
                  nutriments['energy-kcal_100g'] = _parseDouble(nutrientsMap['energy_100g']) / 4.184;
                }
                
                if (nutrientsMap.containsKey('proteins_100g')) {
                  nutriments['proteins_100g'] = _parseDouble(nutrientsMap['proteins_100g']);
                }
                
                if (nutrientsMap.containsKey('carbohydrates_100g')) {
                  nutriments['carbohydrates_100g'] = _parseDouble(nutrientsMap['carbohydrates_100g']);
                }
                
                if (nutrientsMap.containsKey('fat_100g')) {
                  nutriments['fat_100g'] = _parseDouble(nutrientsMap['fat_100g']);
                }
              }
            } catch (e) {
              _logger.warning('Error extracting nutrients: $e');
            }
            
            productMap['nutriments'] = nutriments;
            
            productMaps.add(productMap);
            _logger.info('Successfully processed product: ${productMap['product_name']}');
          } catch (e) {
            _logger.warning('Error processing product: $e');
            // Continue processing other products even if one fails
          }
        }
        
        return productMaps;      } else {
        _logger.warning('No products found for query: "$enhancedQuery"');
        _logger.info('Trying alternative search strategies might help. Check the API response.');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error searching for products: $e\n$stackTrace');
    }
    return [];
  }

  /// Get detailed product info by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    _logger.info('Getting product details for barcode: $barcode');
    try {
      final configuration = ProductQueryConfiguration(
        barcode,
        language: OpenFoodFactsLanguage.ENGLISH,
        fields: [ProductField.ALL],
        version: ProductQueryVersion.v3,
      );
      
      final result = await OpenFoodAPIClient.getProductV3(
        configuration,
        user: const User(userId: '', password: ''),
      );
      
      if (result.status != null && result.status.toString() == '1') { // 1 indicates success in OpenFoodFacts API
        _logger.info('Successfully retrieved product for barcode: $barcode');
        
        if (result.product != null) {
          final product = result.product!;
          // Convert the product to a map using the same approach as in searchProducts
          final Map<String, dynamic> productMap = {
            'product_name': product.productName ?? 'Unknown Product',
            'generic_name': product.genericName ?? '',
            'code': product.barcode ?? barcode,
            'nutriments': {},
            'ingredients_text': product.ingredientsText ?? '',
            'categories_tags': product.categoriesTags ?? [],
            'brands_tags': product.brandsTags ?? [],
            'additional_images': [],
          };
          
          // Handle images and other data similar to searchProducts
          if (product.imageFrontUrl != null && product.imageFrontUrl!.isNotEmpty) {
            productMap['image_front_url'] = product.imageFrontUrl;
          } else if (product.imageFrontSmallUrl != null && product.imageFrontSmallUrl!.isNotEmpty) {
            productMap['image_front_url'] = product.imageFrontSmallUrl;
          } else {
            productMap['image_front_url'] = '';
          }
          
          return productMap;
        }
      } else {
        _logger.warning('No product found for barcode: $barcode');
      }
    } catch (e) {
      _logger.severe('Error getting product by barcode: $e');
    }
    return null;
  }
  
  /// Helper method to safely parse doubles from OpenFoodFacts
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
}
