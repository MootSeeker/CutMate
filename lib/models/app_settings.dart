import 'dart:convert';

/// Settings model for the CutMate app
class AppSettings {
  // For darkMode: null = system default, true = dark, false = light
  final String? themeMode; // 'system', 'dark', or 'light'
  final String weightUnit; // 'kg' or 'lbs'
  final bool showWeightChangeIndicators;
  final bool enableWeeklyReminders;
  final int defaultChartPeriod; // 7, 30, 60, or 90 days
  
  /// Create app settings
  AppSettings({
    this.themeMode = 'system',
    this.weightUnit = 'kg',
    this.showWeightChangeIndicators = true,
    this.enableWeeklyReminders = true,
    this.defaultChartPeriod = 7,
  });
    /// Create a copy of this settings with some changes
  AppSettings copyWith({
    String? themeMode,
    String? weightUnit,
    bool? showWeightChangeIndicators,
    bool? enableWeeklyReminders,
    int? defaultChartPeriod,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      weightUnit: weightUnit ?? this.weightUnit,
      showWeightChangeIndicators: showWeightChangeIndicators ?? this.showWeightChangeIndicators,
      enableWeeklyReminders: enableWeeklyReminders ?? this.enableWeeklyReminders,
      defaultChartPeriod: defaultChartPeriod ?? this.defaultChartPeriod,
    );
  }
  
  /// Convert settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'weightUnit': weightUnit,
      'showWeightChangeIndicators': showWeightChangeIndicators,
      'enableWeeklyReminders': enableWeeklyReminders,
      'defaultChartPeriod': defaultChartPeriod,
    };
  }
  
  /// Create settings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // Handle legacy format where we had useDarkMode instead of themeMode
    String? themeMode;
    if (json.containsKey('useDarkMode')) {
      final bool useDarkMode = json['useDarkMode'] ?? false;
      themeMode = useDarkMode ? 'dark' : 'light';
    } else {
      themeMode = json['themeMode'] ?? 'system';
    }
    
    return AppSettings(
      themeMode: themeMode,
      weightUnit: json['weightUnit'] ?? 'kg',
      showWeightChangeIndicators: json['showWeightChangeIndicators'] ?? true,
      enableWeeklyReminders: json['enableWeeklyReminders'] ?? true,
      defaultChartPeriod: json['defaultChartPeriod'] ?? 7,
    );
  }
  
  /// Create settings from JSON string
  factory AppSettings.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AppSettings.fromJson(json);
  }
  
  /// Default settings
  static AppSettings get defaults => AppSettings();
}
