import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../services/meal_provider.dart';

/// Widget for displaying a meal card with user feedback options
class MealCardWithFeedback extends StatelessWidget {
  final Meal meal;
  final Function? onFeedbackGiven;
  
  const MealCardWithFeedback({
    required this.meal,
    this.onFeedbackGiven,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildMealDetails(),
          _buildFeedbackSection(context),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              meal.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              // Relevance indicator
              if (meal.relevanceScore > 0)
                Tooltip(
                  message: 'Ingredient match score: ${(meal.relevanceScore * 100).toInt()}%',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRelevanceColor(meal.relevanceScore),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(meal.relevanceScore * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Favorite button
              IconButton(
                icon: Icon(
                  meal.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: meal.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  mealProvider.toggleFavorite(meal.id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.description,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nutrition',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            children: [
              _buildNutrientInfo('Calories', '${meal.nutrients['calories']?.round() ?? 0}'),
              _buildNutrientInfo('Protein', '${meal.nutrients['protein']?.round() ?? 0}g'),
              _buildNutrientInfo('Carbs', '${meal.nutrients['carbs']?.round() ?? 0}g'),
              _buildNutrientInfo('Fat', '${meal.nutrients['fat']?.round() ?? 0}g'),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text(
              'View Recipe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              _buildIngredientsList(),
              const SizedBox(height: 8),
              _buildInstructionsList(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutrientInfo(String label, String value) {
    return Chip(
      label: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
  
  Widget _buildIngredientsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...meal.ingredients.map((ingredient) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(ingredient)),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildInstructionsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ...meal.instructions.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.key + 1}. '),
                Expanded(child: Text(entry.value)),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildFeedbackSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Was this recommendation helpful?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFeedbackButton(
                context, 
                true, 
                'Yes', 
                Icons.thumb_up_outlined,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildFeedbackButton(
                context, 
                false, 
                'No', 
                Icons.thumb_down_outlined,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeedbackButton(
    BuildContext context, 
    bool liked, 
    String label, 
    IconData icon,
    Color color,
  ) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: color, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        _provideFeedback(context, liked);
      },
    );
  }
  
  Future<void> _provideFeedback(BuildContext context, bool liked) async {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    
    // For negative feedback, show a dialog to collect more information
    if (!liked) {
      // Check mounted before showing a dialog that depends on the context
      if (!context.mounted) return;
      String? feedback = await _showFeedbackDialog(context);
      // No need to check mounted again before this await, as mealProvider is not UI dependent for this call
      await mealProvider.recordMealFeedback(meal.id, liked, feedback: feedback);
    } else {
      // For positive feedback, just record it
      await mealProvider.recordMealFeedback(meal.id, liked);
    }
    
    // Call the callback if provided
    if (onFeedbackGiven != null) {
      onFeedbackGiven!();
    }
    
    // Check if the widget is still mounted before showing the SnackBar
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thank you for your feedback!'),
        backgroundColor: liked ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Future<String?> _showFeedbackDialog(BuildContext context) async {
    final TextEditingController feedbackController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What could be improved?'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(
            hintText: 'Please tell us what you didn\'t like...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(feedbackController.text),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
  
  Color _getRelevanceColor(double score) {
    if (score > 0.8) return Colors.green;
    if (score > 0.6) return Colors.lightGreen;
    if (score > 0.4) return Colors.amber;
    if (score > 0.2) return Colors.orange;
    return Colors.red;
  }
}
