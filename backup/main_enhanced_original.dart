import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/screens/main_screen.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/services/weight_provider.dart';
import 'package:cutmate/services/meal_provider.dart';
import 'package:cutmate/screens/enhanced_meal_test_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WeightProvider()),
        ChangeNotifierProvider(create: (context) => MealProvider()),
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
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      routes: {
        '/': (context) => MainScreen(),
        '/enhanced-meal-test': (context) => EnhancedMealTestScreen(), // Add this route for testing
      },
      initialRoute: '/',
    );
  }
}

// Example navigation to the enhanced meal test screen (add this to a settings screen or menu):
/*
ElevatedButton(
  onPressed: () {
    Navigator.of(context).pushNamed('/enhanced-meal-test');
  },
  child: const Text('Test Enhanced Meal System'),
),
*/
