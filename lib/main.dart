import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cutmate/screens/main_screen.dart';
import 'package:cutmate/screens/login_screen.dart';
import 'package:cutmate/screens/register_screen.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/services/weight_provider.dart';
import 'package:cutmate/services/meal_provider.dart';
import 'package:cutmate/services/settings_provider.dart';
import 'package:cutmate/services/user_provider.dart';
import 'package:cutmate/services/auth_service.dart';
import 'package:cutmate/theme/app_theme.dart';
import 'package:cutmate/screens/enhanced_meal_test_screen.dart'; // Added from main_enhanced.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
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
      // Initialize user data first
      Provider.of<UserProvider>(context, listen: false).initialize();
      
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
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/main': (context) => const MainScreen(),
            '/enhanced-meal-test': (context) => const EnhancedMealTestScreen(), // Added from main_enhanced.dart
          },
          initialRoute: '/',
        );
      },
    );
  }
}

/// Wrapper widget to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Listen to authentication state changes
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            
            // If user is logged in, show main app
            if (snapshot.hasData && snapshot.data != null) {
              return const MainScreen();
            }
            
            // If no user, show login screen
            return const LoginScreen();
          },
        );
      },
    );
  }
