import 'dart:convert';

/// Settings model for the CutMate app
class AppSettings {
  final bool useDarkMode;
  final String weightUnit; // 'kg' or 'lbs'
  final bool showWeightChangeIndicators;
  final bool enableWeeklyReminders;
  final int defaultChartPeriod; // 7, 30, 60, or 90 days
  
  /// Create app settings
  AppSettings({
    this.useDarkMode = false,
    this.weightUnit = 'kg',
    this.showWeightChangeIndicators = true,
    this.enableWeeklyReminders = true,
    this.defaultChartPeriod = 7,
  });
  
  /// Create a copy of this settings with some changes
  AppSettings copyWith({
    bool? useDarkMode,
    String? weightUnit,
    bool? showWeightChangeIndicators,
    bool? enableWeeklyReminders,
    int? defaultChartPeriod,
  }) {
    return AppSettings(
      useDarkMode: useDarkMode ?? this.useDarkMode,
      weightUnit: weightUnit ?? this.weightUnit,
      showWeightChangeIndicators: showWeightChangeIndicators ?? this.showWeightChangeIndicators,
      enableWeeklyReminders: enableWeeklyReminders ?? this.enableWeeklyReminders,
      defaultChartPeriod: defaultChartPeriod ?? this.defaultChartPeriod,
    );
  }
  
  /// Convert settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'useDarkMode': useDarkMode,
      'weightUnit': weightUnit,
      'showWeightChangeIndicators': showWeightChangeIndicators,
      'enableWeeklyReminders': enableWeeklyReminders,
      'defaultChartPeriod': defaultChartPeriod,
    };
  }
  
  /// Create settings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      useDarkMode: json['useDarkMode'] ?? false,
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
