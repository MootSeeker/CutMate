import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cutmate/models/user.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Provider for managing user data
class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // User is logged in, try to load from Firestore first
        await _loadUserFromFirestore(firebaseUser.uid);
      } else {
        // No user logged in, load from local storage
        await _loadUserFromStorage();
      }
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
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final userId = firebaseUser?.uid ?? _user?.id ?? const Uuid().v4();
      
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
      
      // Save to both local storage and Firestore
      await _saveUserToStorage();
      if (firebaseUser != null) {
        await _saveUserToFirestore();
      }
      
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
  
  /// Load user data from Firestore
  Future<void> _loadUserFromFirestore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        _user = User.fromJson(doc.data()!);
        // Also save to local storage for offline access
        await _saveUserToStorage();
      } else {
        // User document doesn't exist in Firestore, try local storage
        await _loadUserFromStorage();
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
      // Fallback to local storage
      await _loadUserFromStorage();
    }
  }
  
  /// Save user data to Firestore
  Future<void> _saveUserToFirestore() async {
    if (_user == null) return;
    
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    
    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(_user!.toJson());
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
      throw Exception('Failed to sync user data to cloud');
    }
  }
  
  /// Sync user data after login
  Future<void> syncUserDataAfterLogin() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    
    _setLoading(true);
    try {
      // Load from Firestore first
      await _loadUserFromFirestore(firebaseUser.uid);
      
      // If no data in Firestore but we have local data, upload it
      if (_user == null) {
        await _loadUserFromStorage();
        if (_user != null) {
          // Update user ID to match Firebase user ID
          _user = User(
            id: firebaseUser.uid,
            email: _user!.email,
            dateOfBirth: _user!.dateOfBirth,
            heightCm: _user!.heightCm,
            startingWeightKg: _user!.startingWeightKg,
            targetWeightKg: _user!.targetWeightKg,
            targetDate: _user!.targetDate,
            dietaryRestrictions: _user!.dietaryRestrictions,
            preferences: _user!.preferences,
          );
          await _saveUserToFirestore();
          await _saveUserToStorage();
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to sync user data: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Clear user data (for logout)
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
}
