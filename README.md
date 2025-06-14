# CutMate

CutMate is an AI-powered weight loss application primarily for males aged 18-35. The app features personalized goal setting, progress tracking, AI-generated meal suggestions, and shareable visuals with a focus on habit-building and creating viral shareable content.

## Features

- **Personalized Goal Setting**: Set your target weight and timeframe
- **Weight Tracking**: Log your weight daily with optional notes
- **Progress Visualization**: View your weight loss journey through intuitive charts
- **AI Meal Recommendations**: Get meal suggestions tailored to your preferences, available ingredients, and dietary goals using Mistral-7B AI model
- **Shareable Content**: Create and share meal cards and milestone achievements

## Project Status

### Implemented
- ✅ Project structure setup
- ✅ Theme implementation based on brand guidelines
- ✅ App navigation with bottom tab bar
- ✅ Weight entry screen with form validation 
- ✅ Weight data persistence using local storage
- ✅ Progress visualization with charts
- ✅ Home screen with key feature cards

### In Progress
- ✅ Meal recommendation features with AI integration
- ✅ Project structure consolidation and cleanup
- 🔄 User profile management
- 🔄 Shareable content generation

### Pending
- 📝 Social sharing capabilities
- 📝 Integration with fitness tracking APIs
- 📝 Unit and integration tests

## Technology Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Storage**: SharedPreferences
- **Charts**: fl_chart
- **UI Components**: Material Design
- **AI Integration**: Integration with external AI models for meal recommendations

## Project Structure

The project follows a clean architecture approach with the following key components:

- **Models**: Data structures representing core business entities
- **Services**: Business logic and data management
  - `meal_service.dart`: Consolidated service for AI-powered meal recommendations
  - `meal_provider.dart`: State management for meal-related features
  - `weight_provider.dart`: Handles weight tracking functionality
  - `settings_provider.dart`: Manages app settings and preferences
- **Screens**: UI components for different app sections
- **Widgets**: Reusable UI components
- **Constants**: App-wide configuration values
- **Theme**: Styling and visual appearance definitions

## Getting Started

### Prerequisites
- Flutter SDK (version 3.x or higher)
- Android Studio or VS Code with Flutter extensions
- Android or iOS device/emulator

### Installation
1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/cutmate.git
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```