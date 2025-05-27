import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration for CutMate
class AppTheme {
  // Colors from branding document
  static const Color primaryAccent = Color(0xFF2F80FF); // Electric blue - energetic, modern
  static const Color darkSurface = Color(0xFF111827); // Near-black - masculinity, OLED-friendly  
  static const Color lightBackground = Color(0xFFF7F7F7); // Cleanliness, contrast
  static const Color successGoal = Color(0xFF10B981); // Emerald - positive progress
  static const Color warning = Color(0xFFF59E0B); // Friendly amber - gentle nudges

  /// Light theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: lightBackground,
    );
  }

  /// Dark theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        brightness: Brightness.dark,
        background: darkSurface,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: darkSurface,
    );
  }
}
