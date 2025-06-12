import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/screens/main_screen.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/services/weight_provider.dart';
import 'package:cutmate/services/meal_provider.dart';
import 'package:cutmate/services/settings_provider.dart';
import 'package:cutmate/theme/app_theme.dart';
import 'package:cutmate/screens/enhanced_meal_test_screen.dart'; // Added from main_enhanced.dart

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WeightProvider()),
        ChangeNotifierProvider(create: (context) => MealProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
      ],
      child: const CutMateApp(),
    ),
  );
}

class CutMateApp extends StatefulWidget {
  const CutMateApp({super.key});

  @override
  State<CutMateApp> createState() => _CutMateAppState();
}

class _CutMateAppState extends State<CutMateApp> {
  @override
  void initState() {
    super.initState();
    // Initialize data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize weight data
      Provider.of<WeightProvider>(context, listen: false).initialize();
      
      // Initialize meal data
      Provider.of<MealProvider>(context, listen: false).initialize();
      
      // Initialize settings data
      Provider.of<SettingsProvider>(context, listen: false).initialize();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: settingsProvider.getThemeMode(), // Use settings for theme mode
          routes: {
            '/': (context) => const MainScreen(),
            '/enhanced-meal-test': (context) => const EnhancedMealTestScreen(), // Added from main_enhanced.dart
          },
          initialRoute: '/',
        );
      },
    );
  }
}
