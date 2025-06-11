# Enhanced Meal Recommendation System: Moving Beyond AI Models

## Analysis of Current Situation

The AI meal recommendation approach has several drawbacks:

1. **Reliability issues**: External AI model dependencies cause failures when API connections are unstable
2. **Inconsistent results**: Similar queries often produce very different recommendations
3. **Poor ingredient utilization**: Recommendations often don't properly incorporate available ingredients
4. **Performance concerns**: API calls add latency and potential costs

A locally-implemented algorithmic approach would provide greater reliability, consistency, and control.

## Proposed Solution: Algorithmic Meal Recommendation System

### Phase 1: Core Recommendation Engine

1. **Create a comprehensive meal database**
   - Create structured meal data including:
     - Complete nutritional information
     - Required ingredients with quantities
     - Preparation difficulty and time
     - Meal type and tags (breakfast, keto, vegetarian, etc.)

2. **Develop an ingredient matching algorithm**

3. **Implement meal sorting and filtering**
   - Sort by match score
   - Filter by meal types, dietary restrictions
   - Include variety enforcement (avoid recommending the same meals)

### Phase 2: Nutritional Planning Engine

1. **Create user profile model**

2. **Implement calorie and macronutrient calculator**

3. **Develop meal plan optimizer**
   - Create daily/weekly meal plans that meet nutritional goals
   - Balance meals across days for variety and nutritional completeness
   - Adjust portion sizes to meet caloric requirements

### Phase 3: User Preference Learning

1. **Implement feedback tracking**

2. **Create adaptive recommendation algorithm**
   - Adjust recommendations based on user feedback history
   - Incorporate seasonal and time-of-day factors
   - Progressively refine understanding of user preferences

## Implementation Plan

### Sprint 1: Database Setup (2 weeks)
- Design and create meal database schema
- Add 100+ initial meals with complete nutritional info and ingredients
- Implement basic ingredient matching algorithm

### Sprint 2: Core Recommendation Engine (3 weeks)
- Build meal filtering and sorting system
- Implement ingredient substitution logic
- Create meal card UI with better ingredient display
- Add basic user preference storage

### Sprint 3: User Profile & Nutrition Calculator (2 weeks)
- Create user profile UI for entering physical stats and goals
- Implement TDEE and macronutrient calculator
- Add visualization of nutrition goals vs. actual intake

### Sprint 4: Meal Planning & Integration (3 weeks)
- Develop meal plan generator that meets nutrition goals
- Create weekly view of planned meals
- Integrate meal plans with shopping list generator

### Sprint 5: Feedback & Refinement (2 weeks)
- Implement user feedback system
- Add meal rating and preference tracking
- Create adaptive recommendation algorithm that learns from feedback

## Code Example: Core Recommendation Algorithm

```dart
class MealRecommendationEngine {
  final MealDatabase mealDb;
  final UserPreferenceService preferenceService;
  
  MealRecommendationEngine(this.mealDb, this.preferenceService);
  
  Future<List<Meal>> getRecommendations({
    required String userId,
    required List<String> availableIngredients,
    String? mealType,
    int count = 3,
    List<String>? recentlyRecommended,  // To avoid repetition
  }) async {
    // Get user preferences
    final userPrefs = await preferenceService.getUserPreferences(userId);
    
    // Get dietary restrictions
    final restrictions = userPrefs.dietaryRestrictions;
    
    // Query database for eligible meals
    final eligibleMeals = await mealDb.queryMeals(
      mealType: mealType,
      excludeIngredients: restrictions,
      excludeMealIds: recentlyRecommended,
    );
    
    // Score meals based on ingredient availability and preferences
    final scoredMeals = eligibleMeals.map((meal) {
      final score = _calculateMealScore(
        meal, 
        availableIngredients,
        userPrefs,
      );
      return ScoredMeal(meal: meal, score: score);
    }).toList();
    
    // Sort by score (highest first)
    scoredMeals.sort((a, b) => b.score.compareTo(a.score));
    
    // Apply variety rules (avoid too similar meals)
    final diverseRecommendations = _ensureDiversity(scoredMeals);
    
    // Return the top N meals
    return diverseRecommendations
      .take(count)
      .map((sm) => sm.meal)
      .toList();
  }
  
  double _calculateMealScore(
    Meal meal, 
    List<String> availableIngredients,
    UserPreferences userPrefs,
  ) {
    // Base score from ingredient matching (0-1)
    double matchScore = _getIngredientMatchScore(meal.ingredients, availableIngredients);
    
    // Preference boost based on past ratings (0.5-1.5)
    double preferenceMultiplier = _getUserPreferenceMultiplier(meal, userPrefs);
    
    // Season relevance (0.8-1.2)
    double seasonMultiplier = _getSeasonalRelevance(meal);
    
    // Time of day relevance (0.8-1.2)
    double timeOfDayMultiplier = _getTimeOfDayRelevance(meal);
    
    // Calculate final score
    return matchScore * preferenceMultiplier * seasonMultiplier * timeOfDayMultiplier;
  }
  
  // Helper methods for calculating match scores
  double _getIngredientMatchScore(List<String> mealIngredients, List<String> availableIngredients) {
    if (availableIngredients.isEmpty) return 0.5; // Medium score if no ingredients specified
    
    int matchCount = 0;
    for (final ingredient in mealIngredients) {
      for (final available in availableIngredients) {
        if (_ingredientsMatch(ingredient, available)) {
          matchCount++;
          break;
        }
      }
    }
    
    return 0.3 + (0.7 * matchCount / mealIngredients.length);
  }
  
  bool _ingredientsMatch(String mealIngredient, String availableIngredient) {
    return mealIngredient.toLowerCase().contains(availableIngredient.toLowerCase()) ||
           availableIngredient.toLowerCase().contains(mealIngredient.toLowerCase());
  }
}

// Nutrition calculation example
class NutritionCalculator {
  static NutritionGoals calculateDailyGoals(UserNutritionProfile profile) {
    // Calculate BMR using Mifflin-St Jeor Equation
    double bmr;
    if (profile.gender == Gender.male) {
      bmr = 10 * profile.currentWeight + 6.25 * profile.height - 5 * profile.age + 5;
    } else {
      bmr = 10 * profile.currentWeight + 6.25 * profile.height - 5 * profile.age - 161;
    }
    
    // Apply activity multiplier
    double activityMultiplier;
    switch (profile.activityLevel) {
      case ActivityLevel.sedentary:
        activityMultiplier = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        activityMultiplier = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        activityMultiplier = 1.55;
        break;
      case ActivityLevel.veryActive:
        activityMultiplier = 1.725;
        break;
      case ActivityLevel.extraActive:
        activityMultiplier = 1.9;
        break;
    }
    
    double tdee = bmr * activityMultiplier;
    
    // Adjust calories based on weight goal
    double targetCalories;
    switch (profile.goal) {
      case WeightGoal.lose:
        targetCalories = tdee - 500; // 500 calorie deficit for weight loss
        break;
      case WeightGoal.gain:
        targetCalories = tdee + 500; // 500 calorie surplus for weight gain
        break;
      case WeightGoal.maintain:
        targetCalories = tdee;
        break;
    }
    
    // Calculate macronutrients
    // Protein: 2g per kg for muscle building/maintenance
    double proteinGrams = profile.currentWeight * 2;
    double proteinCalories = proteinGrams * 4; // 4 calories per gram
    
    // Fat: 25% of calories
    double fatCalories = targetCalories * 0.25;
    double fatGrams = fatCalories / 9; // 9 calories per gram
    
    // Carbs: remaining calories
    double carbCalories = targetCalories - proteinCalories - fatCalories;
    double carbGrams = carbCalories / 4; // 4 calories per gram
    
    return NutritionGoals(
      calories: targetCalories,
      protein: proteinGrams,
      carbs: carbGrams,
      fat: fatGrams
    );
  }
}

// Meal plan generator example
class MealPlanGenerator {
  final MealDatabase mealDb;
  final NutritionCalculator nutritionCalculator;
  
  MealPlanGenerator(this.mealDb, this.nutritionCalculator);
  
  Future<List<Meal>> generateDailyPlan({
    required UserNutritionProfile profile,
    required List<String> availableIngredients,
    required UserPreferences preferences,
  }) async {
    // Calculate daily nutrition goals
    final goals = NutritionCalculator.calculateDailyGoals(profile);
    
    // Define meal distribution
    final mealDistribution = {
      'breakfast': 0.25, // 25% of daily calories
      'lunch': 0.35,     // 35% of daily calories
      'dinner': 0.30,    // 30% of daily calories
      'snack': 0.10      // 10% of daily calories
    };
    
    final plan = <Meal>[];
    
    // Generate each meal
    for (final entry in mealDistribution.entries) {
      final mealType = entry.key;
      final caloriesPortion = entry.value;
      
      // Calculate target calories for this meal
      final mealCalories = goals.calories * caloriesPortion;
      
      // Get meal recommendations
      final recommendations = await mealDb.findMealsMatching(
        mealType: mealType,
        targetCalories: mealCalories,
        availableIngredients: availableIngredients,
        userPreferences: preferences,
        excludeMealIds: plan.map((m) => m.id).toList(), // Avoid duplicates
      );
      
      if (recommendations.isNotEmpty) {
        plan.add(recommendations.first);
      }
    }
    
    return plan;
  }
}
```

## Benefits of This Approach
1. **Reliability**: No dependency on external services
2. **Personalization**: Better adaptation to user preferences over time
3. **Performance**: Faster response times with local processing
4. **Control**: Full control over recommendation logic and quality
5. **Offline functionality**: Works without internet connection
6. **Cost efficiency**: No API usage fees
