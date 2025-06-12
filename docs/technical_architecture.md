# CutMate Technical Architecture

This document outlines the technical architecture of the CutMate application, including the component structure, data flow, and implementation details.

## Project Structure

```
lib/
├── main.dart                 # Entry point of the application
├── constants/                # App constants and configuration values
│   └── app_constants.dart    # Global constants for the app
├── models/                   # Data models
│   ├── app_settings.dart     # App settings data model
│   ├── meal.dart             # Meal recommendation data model
│   ├── user.dart             # User profile data model
│   └── weight_entry.dart     # Weight entry data model
├── screens/                  # UI screens
│   ├── enhanced_meal_test_screen.dart # Testing interface for enhanced meal recommendations
│   ├── home_screen.dart      # Home screen with feature cards
│   ├── main_screen.dart      # Main screen with bottom navigation
│   ├── meal_screen.dart      # Meal recommendation screen
│   ├── progress_screen.dart  # Weight progress visualization screen
│   ├── settings_screen.dart  # App settings and user preferences screen
│   └── weight_entry_screen.dart # Weight input form screen
├── services/                 # Business logic and data services
│   ├── ai_service.dart       # AI integration service for meal recommendations
│   ├── ingredient_service.dart # Ingredient matching and relevance scoring
│   ├── meal_provider.dart    # Meal recommendation state management
│   ├── meal_service_simple.dart # Meal recommendation service implementation
│   ├── notification_service.dart # Local notifications and reminders
│   ├── settings_provider.dart # App settings state management
│   ├── storage_service.dart  # Local storage operations
│   ├── user_provider.dart    # User profile state management
│   └── weight_provider.dart  # Weight data state management
├── theme/                    # UI theme configuration
│   └── app_theme.dart        # Light/dark theme definitions
└── widgets/                  # Reusable UI components
    └── meal_card_with_feedback.dart # Meal display with user feedback options
```

## Data Flow

The application follows a unidirectional data flow pattern:

1. User interacts with UI (Screens)
2. UI communicates with Provider (WeightProvider)
3. Provider updates data through Services (StorageService)
4. Services persist data to storage (SharedPreferences)
5. UI is updated through Provider listeners

## Component Details

### Models

#### WeightEntry
- Represents a single weight data point
- Contains date, weight value, notes, and source
- Includes serialization methods (toJson/fromJson)

#### User
- Represents user profile and preferences
- Contains personal data, goals, and settings
- Includes serialization methods (toJson/fromJson)

### Services

#### StorageService
- Static methods for data persistence
- Uses SharedPreferences for local storage
- Handles CRUD operations for all app data
- Provides methods to load and save data

#### WeightProvider
- Extends ChangeNotifier for state management
- Maintains a list of weight entries
- Calculates derived values (weight change, trends)
- Notifies listeners when data changes

#### MealProvider
- Extends ChangeNotifier for meal recommendation state
- Maintains a list of meal recommendations
- Supports user feedback and meal favoriting
- Handles ingredient-based meal matching
- Calculates relevance scores for recommendations

#### MealService
- Provides meal recommendation functionality
- Implements fallback meal generation
- Handles meal feedback and preferences
- Supports ingredient-based meal filtering

#### SettingsProvider
- Manages app settings and user preferences
- Handles theme switching (light/dark mode)
- Provides settings persistence
- Notifies listeners when settings change

#### NotificationService
- Manages local notifications and reminders
- Handles notification permissions
- Schedules recurring weight tracking reminders

### Screens

#### MainScreen
- Container for all main app screens
- Manages bottom navigation
- Maintains navigation state

#### HomeScreen
- Entry point for users
- Shows current weight and feature cards
- Navigation to other screens

#### ProgressScreen
- Displays weight tracking visualizations
- Shows weight history as a chart
- Displays statistical data (total change, monthly change)

#### WeightEntryScreen
- Form for entering new weight data
- Includes validation and date selection
- Saves entries to storage via Provider

#### MealScreen
- Displays meal recommendations
- Allows ingredient selection for personalized recommendations
- Shows meal details and nutrition information

#### EnhancedMealTestScreen
- Testing interface for enhanced meal recommendation features
- Supports ingredient-based filtering
- Collects user feedback on meal recommendations

#### SettingsScreen
- User preferences and application settings
- Theme switching options
- Notification preferences
- User profile management

## UI Theme

The application uses a consistent theme defined in `app_theme.dart`:
- Primary accent color: #2F80FF (Electric blue)
- Dark surface color: #111827 (Near-black)
- Success color: #10B981 (Emerald green)
- Warning color: #F59E0B (Amber)
- Font family: Inter with Roboto Mono for numeric values

## State Management

Provider package is used for state management:
- WeightProvider is provided at the app root level
- Consumer widgets are used to access and display data
- State changes trigger UI updates through ChangeNotifier

## Data Persistence

SharedPreferences is used for local data storage:
- Weight entries are stored as JSON strings
- User profile data is stored as a JSON string
- Meal recommendations and user feedback are stored as JSON strings
- App settings are stored as JSON strings
- Data is loaded on app startup and saved on changes

## Enhanced Meal Recommendation System

The meal recommendation system has been enhanced with the following capabilities:
- Ingredient-based meal matching for personalized recommendations
- User feedback collection and preference tracking
- Relevance scoring for meal recommendations
- Fallback meal generation when AI services are unavailable
- Multi-meal type support (breakfast, lunch, dinner, snacks)

### Meal Component Architecture

```
Services Layer
├── meal_provider.dart         # State management for meal recommendations
└── meal_service_simple.dart   # Core business logic for meal recommendations

UI Layer
├── meal_screen.dart           # Primary meal recommendation interface
├── enhanced_meal_test_screen.dart # Testing interface for enhanced features
└── meal_card_with_feedback.dart # Reusable UI component for meal display
```

This architecture provides a clean separation of concerns between UI, state management, and business logic while enabling future enhancements to the meal recommendation system.
