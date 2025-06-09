import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/models/meal.dart';
import 'package:cutmate/models/user.dart';
import 'package:cutmate/services/meal_provider_enhanced.dart';
import 'package:cutmate/widgets/meal_card_with_feedback.dart';

// Common ingredients that users might have
final List<String> commonIngredients = [
  'Chicken', 'Eggs', 'Rice', 'Pasta', 'Potatoes',
  'Broccoli', 'Spinach', 'Tomatoes', 'Onions', 'Garlic',
  'Olive Oil', 'Cheese', 'Greek Yogurt', 'Beans', 'Lentils',
  'Quinoa', 'Avocado', 'Almonds', 'Beef', 'Fish',
];

/// Screen for displaying and generating meal recommendations
class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  String _selectedMealType = AppConstants.mealTypes.first;
  final List<String> _selectedIngredients = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers for the form fields
    for (final mealType in AppConstants.mealTypes) {
      _controllers[mealType] = TextEditingController();
    }
    
    // Initialize the meal provider
    Future.microtask(() {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      mealProvider.initialize();
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Update the selected meal type
  void _selectMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
    });
  }

  /// Add or remove an ingredient from the selected ingredients
  void _toggleIngredient(String ingredient) {
    setState(() {
      if (_selectedIngredients.contains(ingredient)) {
        _selectedIngredients.remove(ingredient);
      } else {
        _selectedIngredients.add(ingredient);
      }
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
      final userPreferences = null; // TODO: Get user preferences from a provider
      
      await mealProvider.getMealRecommendations(
        user: userPreferences,
        mealType: _selectedMealType,
        preferredIngredients: _selectedIngredients,
        availableIngredients: _selectedIngredients.isNotEmpty ? _selectedIngredients : null,
        count: 3, // Generate more meals to improve the recommendation quality
      );
      // No need to notifyListeners here as the provider already does it
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
        title: const Text('Meal Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              // TODO: Navigate to favorites screen
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal type selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What meal would you like?',
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
                        .map((type) => _buildMealTypeChip(type))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Ingredients selector (new)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ingredients you have',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIngredients.clear();
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: commonIngredients
                      .map((ingredient) => _buildIngredientChip(ingredient))
                      .toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Meal recommendations
          Expanded(
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${mealProvider.errorMessage}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _generateMealRecommendation,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }
                
                final recommendation = mealProvider.getRecommendationForMealType(_selectedMealType);
                
                if (recommendation == null) {
                  return _buildEmptyState();
                }
                
                return _buildMealRecommendationCard(recommendation);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGenerating ? null : _generateMealRecommendation,
        child: _isGenerating
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh),
      ),
    );
  }

  /// Build a chip for selecting a meal type
  Widget _buildMealTypeChip(String mealType) {
    final isSelected = mealType == _selectedMealType;
    final emoji = AppConstants.mealTypeEmojis[mealType] ?? '🍽️';
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          children: [
            Text(emoji),
            const SizedBox(width: 4),
            Text(
              mealType.substring(0, 1).toUpperCase() + mealType.substring(1),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        onSelected: (_) => _selectMealType(mealType),
      ),
    );
  }

  /// Build an ingredient chip for selection
  Widget _buildIngredientChip(String ingredient) {
    final isSelected = _selectedIngredients.contains(ingredient);
    
    return FilterChip(
      selected: isSelected,
      label: Text(ingredient),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      onSelected: (_) => _toggleIngredient(ingredient),
    );
  }

  /// Build the empty state when no recommendations are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No meal recommendations yet',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to get personalized meal suggestions',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateMealRecommendation,
            child: const Text('Generate Recommendations'),
          ),
        ],
      ),
    );
  }
  /// Build a card showing a meal recommendation
  Widget _buildMealRecommendationCard(Meal meal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          // Enhanced Meal Card with Feedback
          MealCardWithFeedback(
            meal: meal,
            onFeedbackGiven: () {
              // Refresh the UI when feedback is given
              setState(() {});
            },
          ),
          
          const SizedBox(height: 16),
          
          // Nutrients
          _buildNutrientInfo(meal),
          
          const SizedBox(height: 16),
          
          // Ingredients
          _buildSection(
            title: 'Ingredients',
            icon: Icons.shopping_bag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meal.ingredients
                  .map((ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(ingredient)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          _buildSection(
            title: 'Instructions',
            icon: Icons.format_list_numbered,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meal.instructions
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement sharing functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing coming soon!')),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share This Meal'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Source attribution
          Center(
            child: Text(
              'Generated by ${meal.source.toUpperCase()}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a section with a title and icon
  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  /// Build the nutrient information section
  Widget _buildNutrientInfo(Meal meal) {
    final nutrients = meal.nutrients;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNutrientItem(
              label: 'Calories',
              value: '${nutrients['calories']?.toInt() ?? 0}',
              unit: 'kcal',
            ),
            _buildNutrientItem(
              label: 'Protein',
              value: '${nutrients['protein']?.toInt() ?? 0}',
              unit: 'g',
            ),
            _buildNutrientItem(
              label: 'Carbs',
              value: '${nutrients['carbs']?.toInt() ?? 0}',
              unit: 'g',
            ),
            _buildNutrientItem(
              label: 'Fat',
              value: '${nutrients['fat']?.toInt() ?? 0}',
              unit: 'g',
            ),
          ],
        ),
      ),
    );
  }

  /// Build a nutrient item
  Widget _buildNutrientItem({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
