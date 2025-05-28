# CutMate Development Roadmap

This document outlines the upcoming development tasks for the CutMate application, prioritized by importance and logical sequence.

## Next Development Tasks

### High Priority

1. ~~**Meal Recommendation Screen**~~ ✅ COMPLETED
   - ✅ Create UI for displaying meal recommendations
   - ✅ Implement meal card design with recipe details
   - ✅ Add ingredient selection functionality
   - ✅ Connect to AI service (via provider pattern)

2. **User Profile Management**
   - Create profile screen UI
   - Implement onboarding flow for new users
   - Add goal setting functionality
   - Add dietary preference options

3. **Data Persistence Improvements**
   - Implement proper database solution (SQLite or Hive)
   - Add data backup and restore functionality
   - Create migration path from SharedPreferences

### Medium Priority

4. **AI Integration** (Partially Completed)
   - Connect to OpenAI API for meal suggestions (optional enhancement)
   - ✅ Implement budget monitoring for API usage
   - ✅ Create fallback to local model (Mistral-7B-Instruct)
   - Add caching for recommendations

5. **Social Sharing**
   - Design shareable meal cards
   - Create milestone celebration GIFs
   - Implement native share functionality
   - Add achievement system

6. **UI/UX Improvements**
   - Add animations and transitions
   - Implement dark/light theme toggle
   - Create custom UI components
   - Add accessibility features

### Testing & QA

7. **Testing**
   - Write unit tests for service layer
   - Create widget tests for UI components
   - Implement integration tests for key user flows
   - Set up continuous integration

8. **Performance Optimization**
   - Profile app performance
   - Optimize chart rendering
   - Implement lazy loading where appropriate
   - Reduce app bundle size

## Implementation Details

### Meal Recommendation Screen

The meal recommendation screen will use a new `MealProvider` class to manage state and a `MealService` to handle API calls to the AI service. The UI will feature a card-based layout showing recommended meals with images, macronutrient information, and recipe details.

```dart
class MealRecommendationScreen extends StatelessWidget {
  // Implementation will show recommended meals based on user profile
  // and allow for customization and sharing
}

class MealProvider extends ChangeNotifier {
  // Will handle meal recommendation state
  // Connect to AI service for recommendations
}
```

### User Profile Implementation

The user profile will be managed through a `UserProvider` and will include:

- Personal details (age, height, gender)
- Starting weight and goal weight
- Target date for goal achievement
- Dietary preferences and restrictions
- Activity level

```dart
class ProfileScreen extends StatefulWidget {
  // Will allow users to view and edit their profile
  // Will include goal setting functionality
}

class UserProvider extends ChangeNotifier {
  // Will manage user profile state
  // Handle profile updates and goal calculations
}
```

### AI Budget Monitoring

To keep track of API usage costs, we will implement a simple budget monitoring system:

```dart
class AIBudgetService {
  // Track API usage and costs
  // Switch to fallback model when budget is exceeded
  // Provide usage statistics to user
}
```

## Timeline

- **Phase 1 (2 weeks)**: Complete meal recommendation screen and AI integration
- **Phase 2 (2 weeks)**: User profile management and data persistence improvements
- **Phase 3 (2 weeks)**: Social sharing features and UI/UX improvements
- **Phase 4 (1 week)**: Testing and performance optimization
- **Phase 5**: Public beta release
