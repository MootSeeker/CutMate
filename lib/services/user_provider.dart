import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cutmate/models/user.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

/// Provider for managing user data
class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';

  /// Current user data
  User? get user => _user;
  
  /// Whether the user data is loading
  bool get isLoading => _isLoading;
  
  /// Error message if any
  String get errorMessage => _errorMessage;
  
  /// Whether the user has completed onboarding
  bool get hasCompletedOnboarding => _user != null;

  /// Initialize the provider by loading user data from storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadUserFromStorage();
    } catch (e) {
      _setError('Failed to load user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Save user profile information
  Future<void> saveUserProfile({
    required double heightCm,
    required String? email,
    DateTime? dateOfBirth,
    double? startingWeightKg,
    double? targetWeightKg,
    DateTime? targetDate,
    List<String>? dietaryRestrictions,
    Map<String, dynamic>? preferences,
  }) async {
    _setLoading(true);
    try {
      // If user doesn't exist yet, create a new one with a UUID
      final userId = _user?.id ?? const Uuid().v4();
      
      _user = User(
        id: userId,
        email: email,
        dateOfBirth: dateOfBirth,
        heightCm: heightCm,
        startingWeightKg: startingWeightKg,
        targetWeightKg: targetWeightKg,
        targetDate: targetDate,
        dietaryRestrictions: dietaryRestrictions,
        preferences: preferences,
      );
      
      await _saveUserToStorage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to save user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update dietary restrictions
  Future<void> updateDietaryRestrictions(List<String> restrictions) async {
    if (_user == null) return;
    
    _setLoading(true);
    try {
      _user = User(
        id: _user!.id,
        email: _user!.email,
        dateOfBirth: _user!.dateOfBirth,
        heightCm: _user!.heightCm,
        startingWeightKg: _user!.startingWeightKg,
        targetWeightKg: _user!.targetWeightKg,
        targetDate: _user!.targetDate,
        dietaryRestrictions: restrictions,
        preferences: _user!.preferences,
      );
      
      await _saveUserToStorage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update dietary restrictions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> newPreferences) async {
    if (_user == null) return;
    
    _setLoading(true);
    try {
      final updatedPreferences = {
        ...(_user!.preferences ?? {}),
        ...newPreferences,
      };
      
      _user = User(
        id: _user!.id,
        email: _user!.email,
        dateOfBirth: _user!.dateOfBirth,
        heightCm: _user!.heightCm,
        startingWeightKg: _user!.startingWeightKg,
        targetWeightKg: _user!.targetWeightKg,
        targetDate: _user!.targetDate,
        dietaryRestrictions: _user!.dietaryRestrictions,
        preferences: updatedPreferences,
      );
      
      await _saveUserToStorage();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    _setLoading(true);
    try {
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear user data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = '';
    }
    notifyListeners();
  }
  
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userDataKey);
    
    if (userData != null && userData.isNotEmpty) {
      try {
        final jsonData = json.decode(userData);
        _user = User.fromJson(jsonData);
      } catch (e) {
        throw Exception('Invalid user data format: $e');
      }
    }
  }
  
  Future<void> _saveUserToStorage() async {
    if (_user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final userData = json.encode(_user!.toJson());
    await prefs.setString(AppConstants.userDataKey, userData);
  }
}
