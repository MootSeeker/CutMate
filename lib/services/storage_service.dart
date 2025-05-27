import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/models/user.dart';
import 'package:cutmate/models/weight_entry.dart';

/// Service for handling local storage operations
class StorageService {
  /// Save user data to local storage
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, jsonEncode(user.toJson()));
  }
  
  /// Load user data from local storage
  static Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userDataKey);
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }
  
  /// Save weight entries to local storage
  static Future<void> saveWeightEntries(List<WeightEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(AppConstants.weightEntriesKey, jsonEncode(entriesJson));
  }
  
  /// Add a single weight entry and save to storage
  static Future<void> addWeightEntry(WeightEntry entry) async {
    final entries = await loadWeightEntries();
    entries.add(entry);
    // Sort entries by date, newest first
    entries.sort((a, b) => b.date.compareTo(a.date));
    await saveWeightEntries(entries);
  }
  
  /// Load weight entries from local storage
  static Future<List<WeightEntry>> loadWeightEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesData = prefs.getString(AppConstants.weightEntriesKey);
    
    if (entriesData != null) {
      final List<dynamic> entriesJson = jsonDecode(entriesData);
      return entriesJson
          .map((json) => WeightEntry.fromJson(json))
          .toList();
    }
    return [];
  }
  
  /// Get the latest weight entry, if any
  static Future<WeightEntry?> getLatestWeightEntry() async {
    final entries = await loadWeightEntries();
    if (entries.isNotEmpty) {
      // Sort entries by date, newest first
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries.first;
    }
    return null;
  }
  
  /// Clear all user data from storage (for logout/reset)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.weightEntriesKey);
    await prefs.remove(AppConstants.appSettingsKey);
  }
}
