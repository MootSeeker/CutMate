import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/screens/weight_entry_screen.dart';
import 'package:cutmate/screens/main_screen.dart';
import 'package:cutmate/services/weight_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CutMate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to CutMate',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your AI wingman for weight loss',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              // Weight tracking card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Weight',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Consumer<WeightProvider>(
                            builder: (context, weightProvider, child) {
                              final latestEntry = weightProvider.latestEntry;
                              return Text(
                                latestEntry != null
                                    ? '${latestEntry.weightKg.toStringAsFixed(1)} kg'
                                    : '-- kg',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to weight entry screen and refresh data when we return
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WeightEntryScreen(),
                                ),
                              );
                            },
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Meal recommendation card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Meal Recommendation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Tap to get AI meal recommendations based on your goals',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to meal recommendation screen
                          },
                          child: const Text('Get Recommendations'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Progress tracking card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'View your weight loss journey',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to progress tab - use index 2 (third tab)
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(initialIndex: 2),
                              ),
                            );
                          },
                          child: const Text('View Progress'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),        ),
      ),
    );
  }
}
