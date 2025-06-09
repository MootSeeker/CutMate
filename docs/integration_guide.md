# Integration Guide: Enhanced Meal Recommendation System

This guide outlines the steps needed to integrate the enhanced meal recommendation system into the main CutMate application.

## Overview

The enhanced meal recommendation system includes the following improvements:
- Better ingredient matching and scoring
- Improved AI response parsing with multiple fallback strategies
- User feedback collection and integration
- Enhanced fallback meal selection

## Step-by-Step Integration Instructions

### 1. Replace the existing services with enhanced versions

First, rename the enhanced service files to replace the existing ones:

```bash
# Backup original files
mv lib/services/meal_service.dart lib/services/meal_service.old.dart
mv lib/services/meal_provider.dart lib/services/meal_provider.old.dart

# Move enhanced files to replace them
mv lib/services/meal_service_enhanced.dart lib/services/meal_service.dart
mv lib/services/meal_provider_enhanced.dart lib/services/meal_provider.dart
```

### 2. Update main.dart to use the enhanced provider

Make sure the main.dart file is using the enhanced MealProvider. Update the provider setup:

```dart
// In main.dart
import 'package:provider/provider.dart';
import 'services/meal_provider.dart';

// Inside the MultiProvider setup
ChangeNotifierProvider(create: (_) => MealProvider()),
```

### 3. Replace or update existing meal screens

Option 1: Replace existing MealScreen with the enhanced version
- Use the components from the enhanced_meal_test_screen.dart

Option 2: Gradually update the existing MealScreen
- Update the meal.dart model
- Replace meal cards with MealCardWithFeedback
- Use the ingredient matching logic

### 4. Update the meal card widget

Replace the existing meal card with the MealCardWithFeedback widget:

```dart
// Instead of:
Card(
  child: // your existing meal card implementation
);

// Use:
import '../widgets/meal_card_with_feedback.dart';

MealCardWithFeedback(
  meal: meal,
  onFeedbackGiven: () {
    // Optional callback after feedback is given
  },
),
```

### 5. Test the integration

1. Add a "Test Enhanced System" button to navigate to the EnhancedMealTestScreen
2. Test with various ingredients to verify matching works
3. Test user feedback collection and verify it's stored properly
4. Test the AI response parsing with different responses

### 6. Update user preferences to include meal preferences

Modify the user model to store meal preferences:

```dart
// In user.dart, add:
final List<String> preferredIngredients;
final List<String> dislikedIngredients;
final Map<String, double> ingredientPreferences; // Scores based on feedback
```

### 7. Implement learning from feedback

In the MealProvider class, implement a method to learn from feedback:

```dart
Future<void> learnFromFeedback() async {
  // Load stored feedback
  // Analyze patterns
  // Update user preferences
}
```

## Key Files and Their Purposes

- `meal_service.dart`: Core service for fetching and processing meal recommendations
- `meal_provider.dart`: State management for meal recommendations
- `meal_card_with_feedback.dart`: UI component for displaying meals with feedback options
- `ingredient_service.dart`: Service for ingredient matching and scoring

## Testing the Integration

To fully test the integration:

1. Generate meal recommendations with specific ingredients
2. Verify relevance scores match expectations
3. Provide feedback and check if it's stored correctly
4. Restart the app and verify feedback has persisted
5. Check that meal rankings reflect previous feedback

## Implementation Progress

As of June 9, 2025, the enhanced meal recommendation system is partially integrated:

1. **Completed**:
   - Updated `main.dart` to use the enhanced meal provider
   - Modified `meal_screen.dart` to use the `MealCardWithFeedback` widget
   - Added feedback functionality to meal recommendations

2. **Pending**:
   - Complete the full implementation of user preference learning based on feedback
   - Add comprehensive meal testing with nutritional optimization
   - Implement advanced AI prompting based on user feedback patterns

### Testing the Enhanced System

To test the enhanced meal recommendation system in isolation:

1. Run the application using the enhanced entry point:
```bash
flutter run -t lib/main_enhanced.dart
```

2. Navigate to the "Enhanced Meal Test" screen to see all the advanced features:
   - Ingredient selection with relevance scoring
   - Feedback collection
   - Improved meal recommendations

### Troubleshooting

If you encounter any issues during the integration:

1. **JSON Parsing Failures**:
   - Check that the meal JSON structure matches what the enhanced service expects
   - The system now includes multiple fallback strategies for parsing

2. **Missing Relevance Scores**:
   - Ensure the Meal model includes a relevanceScore field
   - Check that the copyWith method properly handles the relevanceScore parameter

3. **Feedback Not Working**:
   - Verify that the MealProvider is correctly receiving and processing feedback
   - Check storage permissions if feedback data is not being saved

## Future Improvements

After this integration, consider these next steps:

1. **Nutritional Optimization**: Balance meals across the day based on nutritional goals
2. **Visual Ingredient Selection**: Add an image-based ingredient selector
3. **Recipe Variation**: Suggest variations of favorite meals with available ingredients
4. **Weekly Meal Planning**: Generate a full week's meal plan with optimized variety and ingredient usage
