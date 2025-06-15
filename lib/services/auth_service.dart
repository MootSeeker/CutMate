import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Firebase Authentication
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  
  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign up error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign up error: $e');
      throw Exception('Unerwarteter Fehler beim Registrieren');
    }
  }
  
  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign in error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Sign in error: $e');
      throw Exception('Unerwarteter Fehler beim Anmelden');
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      throw Exception('Fehler beim Abmelden');
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Password reset error: $e');
      throw Exception('Fehler beim Senden der Passwort-Reset-E-Mail');
    }
  }
  
  /// Delete current user account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      debugPrint('Delete account error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Delete account error: $e');
      throw Exception('Fehler beim Löschen des Accounts');
    }
  }
  
  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Kein Benutzer mit dieser E-Mail gefunden.';
      case 'wrong-password':
        return 'Falsches Passwort.';
      case 'email-already-in-use':
        return 'Diese E-Mail wird bereits verwendet.';
      case 'weak-password':
        return 'Das Passwort ist zu schwach.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'user-disabled':
        return 'Dieser Benutzer wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Anmeldeversuche. Versuchen Sie es später erneut.';
      case 'operation-not-allowed':
        return 'Diese Anmeldeart ist nicht erlaubt.';
      case 'requires-recent-login':
        return 'Bitte melden Sie sich erneut an, um diese Aktion durchzuführen.';
      default:
        return 'Authentifizierungsfehler: ${e.message}';
    }
  }
}
