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
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
      // Initialize the meal provider
    Future.microtask(() {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      mealProvider.initialize();
    });
  }

  @override
  void dispose() {
    _ingredientController.dispose();
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
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      
      await mealProvider.getMealRecommendations(
        user: null,
        mealType: _selectedMealType,
        preferredIngredients: _selectedIngredients.isNotEmpty ? _selectedIngredients : null,
        availableIngredients: _selectedIngredients.isNotEmpty ? _selectedIngredients : null,
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
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
          _buildIngredientInput(),
          _buildSelectedIngredients(),
          _buildGenerateButton(),
          _buildMealList(),
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

  /// Build the ingredient input field
  Widget _buildIngredientInput() {
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
        ],
      ),
    );
  }

  /// Build the list of selected ingredients
  Widget _buildSelectedIngredients() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  /// Build the list of meal recommendations
  Widget _buildMealList() {    return Expanded(
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
