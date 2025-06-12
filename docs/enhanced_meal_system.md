# Enhanced Meal Recommendation System - Implementation Guide

This guide outlines the improvements to the CutMate meal recommendation system and how to implement them in the application.

## Overview of Changes

The enhanced meal recommendation system addresses several key issues from the original implementation:

1. **Better Ingredient Matching**: The system can now match user ingredients with recipes and score them based on relevance.
2. **Improved JSON Parsing**: More robust handling of AI API responses with multiple fallback strategies.
3. **User Feedback Mechanism**: A system to collect and incorporate user preferences.
4. **Enhanced Fallback System**: When AI generation fails, recommendations are intelligently selected based on available ingredients.

## Files Created or Modified

1. **New Files:**
   - `meal_service_enhanced.dart`: An enhanced version of the meal service with better error handling and ingredient matching
   - `meal_provider_enhanced.dart`: An updated provider that includes user feedback capabilities
   - `meal_card_with_feedback.dart`: A widget to display meals with user feedback UI elements

2. **Existing Files to Replace:**
   - Replace `meal_service.dart` with `meal_service_enhanced.dart`
   - Replace `meal_provider.dart` with `meal_provider_enhanced.dart`

## Implementation Steps

### Step 1: Update the Service Layer

1. Rename or replace the existing service files:
   ```
   mv lib/services/meal_service.dart lib/services/meal_service.dart.bak
   mv lib/services/meal_service_enhanced.dart lib/services/meal_service.dart
   
   mv lib/services/meal_provider.dart lib/services/meal_provider.dart.bak
   mv lib/services/meal_provider_enhanced.dart lib/services/meal_provider.dart
   ```

### Step 2: Update the UI Layer

1. In the meal screen (`lib/screens/meal_screen.dart`), replace the existing meal card with the new feedback-enabled card:

   ```dart
   // Find where meal cards are created in the UI
   // Replace code that creates meal cards with this:
   
   import '../widgets/meal_card_with_feedback.dart';
   
   // Then replace the Card widget with:
   MealCardWithFeedback(
     meal: meal,
     onFeedbackGiven: () {
       // Optional: Refresh the UI or show a message
     },
   )
   ```

### Step 3: Testing the Enhanced Features

1. **Test Ingredient Matching:**
   - Enter ingredients in the meal screen
   - Verify that recommendations use those ingredients
   - Check that the relevance score is displayed correctly

2. **Test AI Response Parsing:**
   - Enable debug logging
   - Generate new meal recommendations
   - Check logs to see if parsing is successful

3. **Test User Feedback:**
   - Give positive/negative feedback on meals
   - Verify that feedback is recorded and affects future recommendations

### Key New Features to Verify

1. **Relevance Scoring:**
   - Each meal now has a `relevanceScore` property (0.0 to 1.0)
   - Meals are sorted by relevance when ingredients are provided
   - UI shows relevance as a percentage

2. **Ingredient Substitution:**
   - System can suggest meals using substitutes for ingredients
   - Try providing ingredients that have common substitutes

3. **Feedback System:**
   - Users can like/dislike meals
   - Negative feedback allows entering reasons
   - Feedback affects future relevance scoring

## Technical Notes

### Ingredient Matching Algorithm

The ingredient matching is performed by `IngredientService.calculateIngredientMatchScore()` which:
- Compares recipe ingredients with available ingredients
- Considers possible substitutions from the substitution table
- Calculates a score based on match percentage
- Factors in efficient use of provided ingredients

### AI Response Parsing

The enhanced parsing algorithm:
1. Tries multiple strategies to parse JSON responses
2. Fixes common JSON formatting errors
3. Falls back to manual text extraction if JSON parsing fails
4. Always returns at least some usable data

## Future Improvements

1. **User Preference Learning (Phase 2):**
   - Analyze feedback patterns to learn user preferences
   - Adjust prompts to the AI based on learned preferences

2. **Nutritional Optimization (Phase 3):**
   - Track and optimize nutritional balance across multiple meals
   - Target specific macronutrient ratios based on user goals
