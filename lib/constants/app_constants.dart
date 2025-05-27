/// Constants used throughout the CutMate app
class AppConstants {
  // App info
  static const String appName = 'CutMate';
  static const String appVersion = '0.1.0';
  static const String appTagline = 'Your AI wingman for weight loss';
  
  // Navigation
  static const String homeRoute = '/';
  static const String weightEntryRoute = '/weight-entry';
  static const String mealRecommendationsRoute = '/meal-recommendations';
  static const String progressRoute = '/progress';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  
  // Storage keys
  static const String userDataKey = 'user_data';
  static const String weightEntriesKey = 'weight_entries';
  static const String appSettingsKey = 'app_settings';
  
  // Feature flags
  static const bool enableAiFallback = true; // Fallback to Mistral when OpenAI budget reached
  
  // Limits
  static const double minWeightKg = 30.0;
  static const double maxWeightKg = 300.0;
  static const double minHeightCm = 120.0;
  static const double maxHeightCm = 220.0;
  
  // Default values
  static const int defaultGoalDurationDays = 90; // 3 months
}
