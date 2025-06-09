import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/meal.dart';
import 'ai_service.dart';
import 'storage_service.dart';
import 'ingredient_service.dart'; // Added for relevance score

class MealService {
  final AiService _aiService;
  final StorageService _storageService;
  final IngredientService _ingredientService; // Added for relevance score
  final String _cacheKey = 'meal_recommendations';
  final Duration _cacheDuration = const Duration(hours: 24);

  MealService(this._aiService, this._storageService, this._ingredientService);

  Future<List<Meal>> getMealRecommendations(
      List<String> ingredients, List<String> preferences) async {
    final cachedData = await _storageService.getCache(_cacheKey);
    if (cachedData != null) {
      final now = DateTime.now();
      final cacheTime = DateTime.parse(cachedData['timestamp']);
      if (now.difference(cacheTime) < _cacheDuration) {
        if (kDebugMode) {
          print('Using cached meal recommendations.');
        }
        final List<dynamic> mealJson = cachedData['data'];
        // Ensure relevanceScore is handled, even from cache
        return mealJson
            .map((json) => Meal.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    if (kDebugMode) {
      print('Fetching new meal recommendations.');
    }
    try {
      final aiResponse = await _aiService.getMealRecommendations(
          ingredients, preferences);
      if (kDebugMode) {
        print('AI Response for meals: $aiResponse');
      }
      List<Meal> meals = await _parseMealsFromAiResponse(aiResponse, ingredients);

      // Sort meals by relevance score in descending order
      meals.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      await _storageService.setCache(
          _cacheKey, meals.map((m) => m.toJson()).toList());
      return meals;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching meals from AI: $e. Using fallback.');
      }
      return _getFallbackMeals(ingredients);
    }
  }

  Future<List<Meal>> _parseMealsFromAiResponse(String response, List<String> userIngredients) async {
    try {
      if (kDebugMode) {
        print("MealService: Attempting to parse AI response: $response");
      }
      final fixedJsonString = _fixJsonString(response);
      if (kDebugMode) {
        print("MealService: Fixed JSON string: $fixedJsonString");
      }

      if (fixedJsonString.trim().isEmpty || fixedJsonString == "[]") {
          if (kDebugMode) {
            print("MealService: Fixed JSON string is empty or an empty array. Attempting to extract from raw text.");
          }
          return await _calculateRelevanceForExtractedMeals(_extractMealsFromText(response, userIngredients), userIngredients);
      }

      List<dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(fixedJsonString);
      } catch (e) {
        if (kDebugMode) {
          print("MealService: JSON decoding failed after fixing. Error: $e. Fixed string was: $fixedJsonString. Attempting to extract from raw text.");
        }
        return await _calculateRelevanceForExtractedMeals(_extractMealsFromText(response, userIngredients), userIngredients);
      }
      
      if (kDebugMode) {
        print("MealService: Successfully decoded JSON: $jsonResponse");
      }

      List<Meal> meals = [];
      if (jsonResponse is List) {
        for (var mealJson in jsonResponse) {
          try {
            if (mealJson is Map<String, dynamic>) {
              Meal meal = Meal.fromJson(mealJson);
              // Relevance score calculation moved to _calculateRelevanceForExtractedMeals or done after list construction
              meals.add(meal);
            } else {
                if (kDebugMode) {
                    print("MealService: Encountered non-map item in JSON list: $mealJson. Trying to extract from its string representation.");
                }
                List<Meal> extractedFromItem = _extractMealsFromText(mealJson.toString(), userIngredients);
                meals.addAll(extractedFromItem); // Add first, calculate relevance later
            }
          } catch (e) {
            if (kDebugMode) {
              print("MealService: Error processing individual meal from JSON list item: $mealJson. Error: $e. Attempting text extraction for this item.");
            }
            List<Meal> extractedFromItem = _extractMealsFromText(mealJson.toString(), userIngredients);
            meals.addAll(extractedFromItem); // Add first, calculate relevance later
          }
        }
      } else if (jsonResponse is Map<String, dynamic>) { // Handle if AI returns a single JSON object instead of a list
          if (kDebugMode) {
              print("MealService: Decoded JSON is a single map, not a list: $jsonResponse. Processing as a single meal.");
          }
          try {
            Meal meal = Meal.fromJson(jsonResponse);
            meals.add(meal);
          } catch (e) {
            if (kDebugMode) {
              print("MealService: Error parsing single meal from JSON map: $jsonResponse. Error: $e. Attempting text extraction.");
            }
            List<Meal> extractedFromSingleMap = _extractMealsFromText(jsonResponse.toString(), userIngredients);
            meals.addAll(extractedFromSingleMap);
          }
      } else {
          if (kDebugMode) {
              print("MealService: Decoded JSON is not a list or map: $jsonResponse. Trying to extract from its string representation.");
          }
          List<Meal> extractedFromUnknownFormat = _extractMealsFromText(jsonResponse.toString(), userIngredients);
          meals.addAll(extractedFromUnknownFormat);
      }

      // Calculate relevance for all meals collected so far
      await _calculateRelevanceForExtractedMeals(meals, userIngredients);

      if (meals.isEmpty && response.trim().isNotEmpty) {
        if (kDebugMode) {
          print("MealService: No meals parsed from JSON structure after initial attempts, trying to extract from raw text response as a fallback.");
        }
        List<Meal> extractedFallback = _extractMealsFromText(response, userIngredients);
        meals = await _calculateRelevanceForExtractedMeals(extractedFallback, userIngredients);
      }
      
      if (kDebugMode) {
        print("MealService: Parsed ${meals.length} meals after all attempts in try block.");
      }
      return meals;

    } catch (e, s) { 
      if (kDebugMode) {
        print('MealService: Outer catch - Error parsing meals from AI response: $e. Stacktrace: $s. Response was: $response');
        print('MealService: Outer catch - Attempting to extract meals from text due to error.');
      }
      // Fallback extraction and relevance calculation
      List<Meal> extractedOnError = _extractMealsFromText(response, userIngredients);
      return await _calculateRelevanceForExtractedMeals(extractedOnError, userIngredients);
    }
  }

  String _fixJsonString(String jsonString) {
    String fixed = jsonString.trim();

    // Remove potential markdown code block fences
    if (fixed.startsWith("```json")) {
      fixed = fixed.substring(7);
      if (fixed.endsWith("```")) {
        fixed = fixed.substring(0, fixed.length - 3);
      }
    } else if (fixed.startsWith("```")) {
      fixed = fixed.substring(3);
      if (fixed.endsWith("```")) {
        fixed = fixed.substring(0, fixed.length - 3);
      }
    }
    fixed = fixed.trim();

    if (fixed.isEmpty) {
        return "[]"; // Return empty JSON array string if original string was empty or whitespace
    }

    // Attempt to detect if it's already a valid JSON array or object before wrapping
    bool looksLikeJsonArray = fixed.startsWith('[') && fixed.endsWith(']');
    bool looksLikeJsonObject = fixed.startsWith('{') && fixed.endsWith('}');

    if (!looksLikeJsonArray && !looksLikeJsonObject) {
        // If it doesn't look like a JSON array or object, try to wrap it as an array
        // This is a common case if the AI returns multiple JSON objects not enclosed in an array
        fixed = '[$fixed]'; 
        // This might create issues if `fixed` was a single object, e.g. `{[...]}`. 
        // A more robust solution would be to try parsing, and if it fails and it's not an array, then wrap.
        // For now, this simpler approach is taken.
    } else if (looksLikeJsonArray && fixed == "[]") {
        // If it's an empty array string, it's fine.
    } else if (looksLikeJsonObject) {
        // If it's a single object, wrap it in an array for consistent processing.
        fixed = '[$fixed]';
    }

    // Regex replacements for common JSON issues
    // Ensure keys are double-quoted
    fixed = fixed.replaceAllMapped(RegExp(r'([{,]\s*)'?([a-zA-Z0-9_]+)'?(\s*):'), (match) {
      return '${match[1]}"${match[2]}"${match[3]}:';
    });
    // Ensure string values are double-quoted (handles simple cases)
    fixed = fixed.replaceAllMapped(RegExp(r':\s*\'([^\']*)\''), (match) {
      return ':"${match[1]}"';
    });

    // Remove trailing commas before ']' or '}'
    fixed = fixed.replaceAll(RegExp(r',(\s*(?=]))'), r'$1'); // remove comma before closing bracket
    fixed = fixed.replaceAll(RegExp(r',(\s*(?=}))'), r'$1'); // remove comma before closing brace
    
    // Attempt to fix unquoted literal values (true, false, null, numbers) if they were accidentally quoted
    // This is less common but can happen.
    // fixed = fixed.replaceAllMapped(RegExp(r':\s*"(true|false|null|-?\d*\.?\d+)"\s*([,}])'), (match) {
    //     return ':${match[1]}${match[2]}';
    // });

    // Attempt to fix unquoted string values that are simple words
    fixed = fixed.replaceAllMapped(RegExp(r':\s*([a-zA-Z_][a-zA-Z0-9_\s-]*[a-zA-Z0-9_])(\s*[,}])'), (match) {
        // Check if the matched group is not true, false, or null before quoting
        String potentialValue = match[1]!;
        if (potentialValue != 'true' && potentialValue != 'false' && potentialValue != 'null' && !RegExp(r'^-?\d*\.?\d+$').hasMatch(potentialValue)) {
            return ':"$potentialValue"${match[2]}';
        }
        return ':$potentialValue${match[2]}'; // Return as is if it's a boolean, null, or number
    });

    return fixed;
  }

  // Helper method to calculate relevance scores for a list of meals
  Future<List<Meal>> _calculateRelevanceForExtractedMeals(List<Meal> meals, List<String> userIngredients) async {
    for (var meal in meals) {
        meal.relevanceScore = await _ingredientService.calculateIngredientMatchScore(meal.ingredients, userIngredients);
    }
    return meals;
  }

  List<Meal> _extractMealsFromText(String text, List<String> userIngredients) {
    if (kDebugMode) {
      print("Attempting to extract meals from text: $text");
    }
    final List<Meal> meals = [];
    // Regex to find meal structures, more flexible
    final RegExp mealRegex = RegExp(
        r"{\s*['""]?name['""]?\s*:\s*['""]([^'""]+)['""]\s*,\s*['""]?description['""]?\s*:\s*['""]([^'""]+)['""]\s*,\s*['""]?ingredients['""]?\s*:\s*\[([^\]]+)\]\s*,\s*['""]?calories['""]?\s*:\s*(\d+)\s*}",
        caseSensitive: false,
        multiLine: true);

    final matches = mealRegex.allMatches(text);

    if (kDebugMode) {
      print("Found ${matches.length} potential meals via regex.");
    }

    for (final match in matches) {
      try {
        final name = match.group(1)?.trim() ?? 'Unknown Meal';
        final description = match.group(2)?.trim() ?? 'No description';
        final ingredientsString = match.group(3) ?? '';
        final calories = int.tryParse(match.group(4) ?? '0') ?? 0;

        final ingredientsList = ingredientsString
            .split(',')
            .map((e) => e.replaceAll(RegExp(r"['""]"), "").trim())
            .where((i) => i.isNotEmpty)
            .toList();
        
        // Basic relevance for extracted meals, can be refined
        double relevance = 0.0; 
        // Actual calculation will be done after creating the Meal object
        // and calling _ingredientService.calculateIngredientMatchScore

        meals.add(Meal(
          id: Random().nextInt(100000).toString(), // Generate a temporary ID
          name: name,
          description: description,
          ingredients: ingredientsList,
          calories: calories,
          isFavorite: false,
          relevanceScore: relevance, // Placeholder, will be updated
          feedback: '',
        ));
      } catch (e) {
        if (kDebugMode) {
          print("Error extracting a meal with regex: $e. Match: ${match.input}");
        }
      }
    }
     if (kDebugMode) {
      print("Extracted ${meals.length} meals from text.");
    }
    return meals;
  }

  // Helper function for Levenshtein distance (if needed for _fixJsonString or _extractMealsFromText, though not directly used now)
  int _min(int a, int b, int c) {
    return min(min(a, b), c);
  }


  Future<List<Meal>> _getFallbackMeals(List<String> userIngredients) async {
    if (kDebugMode) {
      print('Providing fallback meals.');
    }
    List<Meal> fallback = [
      Meal(id: 'fb1', name: 'Fallback Salad', description: 'A simple fallback salad.', ingredients: ['lettuce', 'tomato', 'cucumber'], calories: 150, relevanceScore: 0.0),
      Meal(id: 'fb2', name: 'Fallback Pasta', description: 'Basic pasta with tomato sauce.', ingredients: ['pasta', 'tomato sauce', 'cheese'], calories: 400, relevanceScore: 0.0),
      Meal(id: 'fb3', name: 'Fallback Chicken and Rice', description: 'Plain chicken and rice.', ingredients: ['chicken', 'rice', 'broccoli'], calories: 500, relevanceScore: 0.0),
    ];
    // Calculate relevance for fallback meals
    for (var meal in fallback) {
        meal.relevanceScore = await _ingredientService.calculateIngredientMatchScore(meal.ingredients, userIngredients);
    }
    // Sort fallback meals by relevance
    fallback.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return fallback;
  }

  Future<void> toggleFavorite(Meal meal) async {
    meal.isFavorite = !meal.isFavorite;
    // This is a simplified example. In a real app, you\'d persist this change.
    // For instance, update it in _storageService or a database.
    if (kDebugMode) {
      print('Meal ${meal.name} favorite status: ${meal.isFavorite}');
    }
    // Example: Persist all meals if they are stored together, or update a specific entry
    // This requires knowing how meals are stored and identified for updates.
    // For now, we assume the meal object is updated in memory and UI reflects this.
  }

  Future<void> recordMealFeedback(Meal meal, String feedback) async {
    meal.feedback = feedback;
    // Persist this feedback.
    if (kDebugMode) {
      print('Feedback for ${meal.name}: $feedback');
    }
    // Example: _storageService.updateMealFeedback(meal.id, feedback);
  }

  // Placeholder for fetching a single meal, e.g., for a detail view
  Future<Meal?> getMealById(String id) async {
    // This would typically fetch from a database or a more persistent cache
    // For now, it\'s a placeholder.
    if (kDebugMode) {
      print('Fetching meal by ID: $id (placeholder)');
    }
    // Simulate fetching by trying to find it in a general cache if available
    // This is not robust for individual meal fetching.
    final cachedData = await _storageService.getCache(_cacheKey);
    if (cachedData != null) {
      final List<dynamic> mealJson = cachedData['data'];
      final mealData = mealJson.firstWhere((m) => m['id'] == id, orElse: () => null);
      if (mealData != null) {
        return Meal.fromJson(mealData as Map<String, dynamic>);
      }
    }
    return null;
  }
}