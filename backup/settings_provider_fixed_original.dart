import 'package:flutter/material.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/models/app_settings.dart';
import 'package:cutmate/services/storage_service.dart';
import 'package:cutmate/services/notification_service_simple.dart';

/// Provider class for app settings
class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings.defaults;
  bool _initialized = false;
  
  /// Get current app settings
  AppSettings get settings => _settings;
  
  /// Get the current theme mode
  String get themeMode => _settings.themeMode ?? 'system';
  
  /// The current weight unit (kg or lbs)
  String get weightUnit => _settings.weightUnit;
  
  /// Whether to show weight change indicators
  bool get showWeightChangeIndicators => _settings.showWeightChangeIndicators;
  
  /// Whether to enable weekly reminders
  bool get enableWeeklyReminders => _settings.enableWeeklyReminders;
  
  /// The default chart period in days
  int get defaultChartPeriod => _settings.defaultChartPeriod;
  
  /// Initialize the provider with data from storage
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    
    // Load settings from storage
    final data = await StorageService.loadData(AppConstants.appSettingsKey);
    if (data != null) {
      _settings = AppSettings.fromJson(data);
      
      // Setup notifications based on saved settings
      await notificationService.setupWeeklyReminder(
        enabled: _settings.enableWeeklyReminders,
      );
    }
    
    _initialized = true;
    notifyListeners();
  }
  
  /// Update theme mode setting
  Future<void> setThemeMode(String value) async {
    if (_settings.themeMode == value) return;
    
    final newSettings = _settings.copyWith(themeMode: value);
    await _updateSettings(newSettings);
  }
  
  /// Update weight unit setting
  Future<void> setWeightUnit(String value) async {
    if (_settings.weightUnit == value) return;
    
    final newSettings = _settings.copyWith(weightUnit: value);
    await _updateSettings(newSettings);
  }
  
  /// Update weight change indicators setting
  Future<void> setShowWeightChangeIndicators(bool value) async {
    if (_settings.showWeightChangeIndicators == value) return;
    
    final newSettings = _settings.copyWith(showWeightChangeIndicators: value);
    await _updateSettings(newSettings);
  }
  
  /// Update weekly reminders setting
  Future<void> setEnableWeeklyReminders(bool value) async {
    if (_settings.enableWeeklyReminders == value) return;
    
    // Update settings
    final newSettings = _settings.copyWith(enableWeeklyReminders: value);
    await _updateSettings(newSettings);
    
    // Update notification schedule
    final notificationService = NotificationService();
    await notificationService.setupWeeklyReminder(enabled: value);
  }
  
  /// Update default chart period setting
  Future<void> setDefaultChartPeriod(int value) async {
    if (_settings.defaultChartPeriod == value) return;
    
    final newSettings = _settings.copyWith(defaultChartPeriod: value);
    await _updateSettings(newSettings);
  }
  
  /// Update all settings at once
  Future<void> updateAllSettings(AppSettings newSettings) async {
    await _updateSettings(newSettings);
  }
  
  /// Helper method to update settings and save to storage
  Future<void> _updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await StorageService.saveData(AppConstants.appSettingsKey, _settings.toJson());
    notifyListeners();
  }
  
  /// Get theme mode based on settings
  ThemeMode getThemeMode() {
    switch(_settings.themeMode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  /// Convert weight from kg to current unit (kg or lbs)
  double convertToDisplayUnit(double weightInKg) {
    if (_settings.weightUnit == 'kg') {
      return weightInKg;
    } else {
      return kgToLbs(weightInKg);
    }
  }
  
  /// Convert weight from current unit (kg or lbs) to kg for storage
  double convertToStorageUnit(double displayWeight) {
    if (_settings.weightUnit == 'kg') {
      return displayWeight;
    } else {
      return lbsToKg(displayWeight);
    }
  }
  
  /// Convert from kg to lbs
  static double kgToLbs(double kg) {
    return kg * 2.20462;
  }
  
  /// Convert from lbs to kg
  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }
  
  /// Get the current weight unit suffix (kg or lbs)
  String get weightUnitSuffix => _settings.weightUnit;
}