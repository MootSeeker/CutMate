import 'package:flutter/material.dart';
import 'package:cutmate/screens/home_screen.dart';
import 'package:cutmate/theme/app_theme.dart';

void main() {
  runApp(const CutMateApp());
}

class CutMateApp extends StatelessWidget {
  const CutMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CutMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system, // Respect system theme
      home: const HomeScreen(),
    );
  }
}

// HomeScreen class moved to lib/screens/home_screen.dart
