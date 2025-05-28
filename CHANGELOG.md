# Changelog

All notable changes to the CutMate project will be documented in this file.

## [Unreleased]

### Added
- Data persistence service for weight entries using SharedPreferences
- Weight provider for state management using Provider pattern
- Progress screen with weight history visualization using fl_chart
- Weight tracking functionality with form validation
- Navigation between screens (Home, Progress, Weight Entry)
- Home screen shows latest weight entry from storage
- Meal recommendation screen with Mistral-7B AI integration
- Ingredient selection for personalized meal recommendations
- Fallback meal suggestions when AI service is unavailable

### Changed
- MainScreen now accepts initialIndex parameter for direct navigation to tabs
- Home screen buttons navigate to appropriate screens
- Updated app structure to follow Flutter best practices

### Fixed
- Theme implementation to correctly apply brand colors
- Bottom navigation bar state management
- UI layout issues in progress screen

## [0.1.0] - 2023-05-20

### Added
- Initial project setup
- Basic Flutter application with "Hello World" display
- Project structure (lib/screens, lib/models, lib/services, etc.)
- GitHub repository setup with documentation