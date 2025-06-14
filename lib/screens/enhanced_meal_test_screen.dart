import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../services/meal_provider.dart';
import '../widgets/meal_card_with_feedback.dart';

/// Demo screen for testing the enhanced meal recommendation system
class EnhancedMealTestScreen extends StatefulWidget {
  const EnhancedMealTestScreen({super.key});

  @override
  State<EnhancedMealTestScreen> createState() => _EnhancedMealTestScreenState();
}

class _EnhancedMealTestScreenState extends State<EnhancedMealTestScreen> {
  String _selectedMealType = AppConstants.mealTypes.first;
  final List<String> _selectedIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController(text: '600'); // Default to 600 calories
  bool _isGenerating = false;
  @override
  void initState() {
    super.initState();
      // Initialize the meal provider
    Future.microtask(() {
      // Check if the widget is still mounted before accessing context
      if (!mounted) return;
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      mealProvider.initialize();
    });
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _caloriesController.dispose(); // Dispose the new controller
    super.dispose();
  }

  /// Update the selected meal type
  void _selectMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
    });
  }

  /// Add a new ingredient to the selected ingredients
  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty) {
      setState(() {
        _selectedIngredients.add(ingredient);
        _ingredientController.clear();
      });
    }
  }

  /// Remove an ingredient from the selected ingredients
  void _removeIngredient(String ingredient) {
    setState(() {
      _selectedIngredients.remove(ingredient);
    });
  }
  /// Generate a new meal recommendation
  Future<void> _generateMealRecommendation() async {
    if (_isGenerating) return;
    
    setState(() {
      _isGenerating = true;
    });
      try {
      // Store the provider reference before any async operation
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      
      // Parse target calories from the input field
      double? targetCalories;
      if (_caloriesController.text.isNotEmpty) {
        try {
          targetCalories = double.parse(_caloriesController.text);
        } catch (e) {
          // Invalid number format, ignore and use default
        }
      }
      
      await mealProvider.getMealRecommendations(
        user: null,
        mealType: _selectedMealType,
        preferredIngredients: _selectedIngredients.isNotEmpty ? _selectedIngredients : null,
        availableIngredients: _selectedIngredients.isNotEmpty ? _selectedIngredients : null,
        targetCalories: targetCalories, // Pass the target calories
      );
      
      // Check if the widget is still mounted before continuing
      if (!mounted) return;
    } finally {
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Meal Recommendations'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealTypeSelector(),
          _buildIngredientSection(),
          _buildCalorieInput(), // New method for calories input
          _buildGenerateButton(),
          _buildRecommendations(),
        ],
      ),
    );
  }

  /// Build the calorie input field
  Widget _buildCalorieInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Target Calories:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    hintText: 'Enter target calories (e.g., 600)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build the meal type selector
  Widget _buildMealTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Meal Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppConstants.mealTypes
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('${AppConstants.mealTypeEmojis[type]} $type'),
                        selected: _selectedMealType == type,
                        onSelected: (_) => _selectMealType(type),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the ingredient selection section
  Widget _buildIngredientSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Available Ingredients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  decoration: const InputDecoration(
                    hintText: 'Enter an ingredient (e.g., chicken)',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addIngredient,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Selected Ingredients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedIngredients
                .map(
                  (ingredient) => Chip(
                    label: Text(ingredient),
                    onDeleted: () => _removeIngredient(ingredient),
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
  
  /// Build the generate button
  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateMealRecommendation,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
        child: _isGenerating
            ? const CircularProgressIndicator()
            : const Text('Generate Meal Recommendations'),
      ),
    );
  }
  
  /// Build the recommendations section
  Widget _buildRecommendations() {
    return Expanded(
      child: Consumer<MealProvider>(
        builder: (context, mealProvider, child) {
          if (mealProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (mealProvider.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${mealProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }          if (mealProvider.recommendations.isEmpty) {
            return const Center(
              child: Text('No meal recommendations yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: mealProvider.recommendations.length,
            itemBuilder: (context, index) {
              final meal = mealProvider.recommendations[index];
              return MealCardWithFeedback(
                meal: meal,
                onFeedbackGiven: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your feedback!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
