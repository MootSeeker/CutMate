import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cutmate/constants/app_constants.dart';
import 'package:cutmate/models/meal.dart';
import 'package:cutmate/services/meal_provider.dart';
import 'package:cutmate/widgets/meal_card_with_feedback.dart';
import 'package:cutmate/widgets/smooth_circular_progress.dart';

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
  final TextEditingController _caloriesController = TextEditingController(text: '600'); // Default to 600 calories
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
      // Check if the widget is still mounted before accessing context
      if (!mounted) return;
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      mealProvider.initialize();
    });  }

  @override
  void dispose() {
    // Dispose controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _caloriesController.dispose(); // Dispose calorie controller
    super.dispose();
  }
    /// Get descriptive text for the current generation progress stage
  String _getProgressStageText(double progress) {
    if (progress <= 10) {
      return 'Starting meal generation...';
    } else if (progress <= 25) {
      return 'Checking meal services...';
    } else if (progress <= 40) {
      return 'Analyzing ingredients...';
    } else if (progress <= 50) {
      return 'Processing ingredient data...';
    } else if (progress <= 65) {
      return 'Searching ingredient database...';
    } else if (progress <= 70) {
      return 'Creating recipe...';
    } else if (progress <= 75) {
      return 'Retrieving meal information...';
    } else if (progress <= 85) {
      return 'Processing nutritional data...';
    } else if (progress <= 95) {
      return 'Finalizing recipe details...';
    } else {
      return 'Completing your meal recommendation...';
    }
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
      // Store the provider reference before any async operation
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      const userPreferences = null; // TODO: Get user preferences from a provider
      
      // Parse target calories from the input field
      double? targetCalories;
      if (_caloriesController.text.isNotEmpty) {
        try {
          targetCalories = double.parse(_caloriesController.text);
        } catch (e) {
          // Invalid number format, use default (null will use default in provider)
        }
      }
      
      await mealProvider.getMealRecommendations(
        user: userPreferences,
        mealType: _selectedMealType,
        preferredIngredients: _selectedIngredients,
        availableIngredients: _selectedIngredients.isNotEmpty ? _selectedIngredients : null,
        count: 3, // Generate more meals to improve the recommendation quality
        targetCalories: targetCalories, // Pass target calories to the provider
      );
      // No need to notifyListeners here as the provider already does it
      
      // Check if the widget is still mounted before setting state
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
          
          // Ingredients selector
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
          
          // Calories input field (new)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Calories:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    hintText: 'Enter target calories (e.g., 600)',
                    border: OutlineInputBorder(),
                    suffixText: 'kcal',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
            // Generate Meal Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: Consumer<MealProvider>(
                builder: (context, mealProvider, child) {
                  return ElevatedButton.icon(                    onPressed: _isGenerating ? null : _generateMealRecommendation,
                    icon: _isGenerating 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SmoothCircularProgress(
                                value: mealProvider.generationProgress > 0 
                                    ? mealProvider.generationProgress / 100 
                                    : null,
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 2.0,
                                pulsing: true,
                              ),
                              if (mealProvider.generationProgress > 0)
                                AnimatedPercentageText(
                                  percentage: mealProvider.generationProgress,
                                  includeSymbol: false,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const Icon(Icons.restaurant_menu),
                    label: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isGenerating 
                            ? (mealProvider.generationProgress > 0 
                                ? 'Generating... ${mealProvider.generationProgress.toInt()}%' 
                                : 'Generating...') 
                            : 'Generate Meal',
                        key: ValueKey<String>(_isGenerating ? 'generating' : 'generate'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
          
          const SizedBox(height: 16),
            // Meal recommendations
          Expanded(
            child: Consumer<MealProvider>(
              builder: (context, mealProvider, child) {                if (mealProvider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SmoothCircularProgress(
                              value: mealProvider.generationProgress > 0 
                                  ? mealProvider.generationProgress / 100 
                                  : null,
                              strokeWidth: 4.0,
                              color: Theme.of(context).colorScheme.primary,
                              backgroundColor: Theme.of(context).colorScheme.surface,
                            ),
                            if (mealProvider.generationProgress > 0)
                              AnimatedPercentageText(
                                percentage: mealProvider.generationProgress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Generating your meal...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (mealProvider.generationProgress > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Text(
                                _getProgressStageText(mealProvider.generationProgress),
                                key: ValueKey<String>(_getProgressStageText(mealProvider.generationProgress)),
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
              'Generated by ${meal.source.toString().toUpperCase()}',
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
