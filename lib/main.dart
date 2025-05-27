import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/screens/main_screen.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/services/weight_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WeightProvider()),
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
    // Initialize weight data when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WeightProvider>(context, listen: false).initialize();
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        primaryColor: const Color(0xFF2F80FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F80FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: const Color(0xFF2F80FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F80FF),
          brightness: Brightness.dark,
          background: const Color(0xFF111827),
        ),
        scaffoldBackgroundColor: const Color(0xFF111827),
      ),
      themeMode: ThemeMode.system, // Respect system theme
      home: const MainScreen(),
    );
  }
}

// HomeScreen class moved to lib/screens/home_screen.dart
