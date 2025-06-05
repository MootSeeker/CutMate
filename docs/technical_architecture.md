# CutMate Technical Architecture

This document outlines the technical architecture of the CutMate application, including the component structure, data flow, and implementation details.

## Project Structure

```
lib/
├── main.dart                 # Entry point of the application
├── constants/                # App constants and configuration values
│   └── app_constants.dart    # Global constants for the app
├── models/                   # Data models
│   ├── user.dart             # User profile data model
│   └── weight_entry.dart     # Weight entry data model
├── screens/                  # UI screens
│   ├── home_screen.dart      # Home screen with feature cards
│   ├── main_screen.dart      # Main screen with bottom navigation
│   ├── progress_screen.dart  # Weight progress visualization screen
│   └── weight_entry_screen.dart # Weight input form screen
├── services/                 # Business logic and data services
│   ├── storage_service.dart  # Local storage operations
│   └── weight_provider.dart  # Weight data state management
├── theme/                    # UI theme configuration
│   └── app_theme.dart        # Light/dark theme definitions
└── widgets/                  # Reusable UI components
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
- Handles CRUD operations for weight entries and user data
- Provides methods to load and save data

#### WeightProvider
- Extends ChangeNotifier for state management
- Maintains a list of weight entries
- Calculates derived values (weight change, trends)
- Notifies listeners when data changes

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
- Data is loaded on app startup and saved on changes
