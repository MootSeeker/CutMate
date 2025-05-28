/// Model class for meal recommendations
class Meal {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, double> nutrients;
  final String imageUrl;
  final DateTime createdAt;
  final String source; // 'openai', 'mistral', etc.
  final bool isFavorite;
  
  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.nutrients,
    this.imageUrl = '',
    required this.createdAt,
    required this.source,
    this.isFavorite = false,
  });
  
  /// Create a meal from JSON data
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      nutrients: Map<String, double>.from(json['nutrients']),
      imageUrl: json['image_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      source: json['source'],
      isFavorite: json['is_favorite'] ?? false,
    );
  }
  
  /// Convert meal to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrients': nutrients,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'source': source,
      'is_favorite': isFavorite,
    };
  }
  
  /// Create a copy of the meal with updated properties
  Meal copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    Map<String, double>? nutrients,
    String? imageUrl,
    DateTime? createdAt,
    String? source,
    bool? isFavorite,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutrients: nutrients ?? this.nutrients,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
