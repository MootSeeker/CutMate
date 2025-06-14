/// Model class for meal recommendations
class Meal {
  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, double> nutrients;
  final String imageUrl;
  final List<String> additionalImages; // Additional product images for meal
  final DateTime createdAt;
  final MealSource source; // "openai", "mistral", etc.
  final bool isFavorite;
  final double relevanceScore; // Score based on ingredients match, higher is better
  final String? notes; // Notes about the meal (e.g., scaling information)
  final List<String>? allergenInfo; // Allergen information if available
  final String? preparationTime; // Estimated preparation time
  final String? category; // Meal category
  final List<String>? tags; // Tags for filtering/categorization
  final List<Map<String, dynamic>>? userFeedback; // User feedback history
  final DateTime? lastUpdated; // Last update timestamp
  final int? servings; // Number of servings
  
  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.nutrients,
    this.imageUrl = "",
    this.additionalImages = const [],
    required this.createdAt,
    required this.source,
    this.isFavorite = false,
    this.relevanceScore = 0.0,
    this.notes,
    this.allergenInfo,
    this.preparationTime,
    this.category,
    this.tags,
    this.userFeedback,
    this.lastUpdated,
    this.servings,
  });
  
  /// Create a meal from JSON data
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      ingredients: List<String>.from(json["ingredients"]),
      instructions: List<String>.from(json["instructions"]),
      nutrients: Map<String, double>.from(json["nutrients"]),
      imageUrl: json["image_url"] ?? "",
      additionalImages: json["additional_images"] != null 
          ? List<String>.from(json["additional_images"]) 
          : [],
      createdAt: DateTime.parse(json["created_at"]),
      source: MealSource.fromString(json["source"]),
      isFavorite: json["is_favorite"] ?? false,
      relevanceScore: (json["relevance_score"] ?? 0.0).toDouble(),
      notes: json["notes"],
      allergenInfo: json["allergen_info"] != null 
          ? List<String>.from(json["allergen_info"]) 
          : null,
      preparationTime: json["preparation_time"],
      category: json["category"],
      tags: json["tags"] != null 
          ? List<String>.from(json["tags"]) 
          : null,
      userFeedback: json["user_feedback"] != null 
          ? List<Map<String, dynamic>>.from(json["user_feedback"]) 
          : null,
      lastUpdated: json["last_updated"] != null 
          ? DateTime.parse(json["last_updated"]) 
          : null,
      servings: json["servings"],
    );
  }
  
  /// Convert meal to JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "ingredients": ingredients,
      "instructions": instructions,
      "nutrients": nutrients,
      "image_url": imageUrl,
      "additional_images": additionalImages,
      "created_at": createdAt.toIso8601String(),
      "source": source.value,
      "is_favorite": isFavorite,
      "relevance_score": relevanceScore,
      if (notes != null) "notes": notes,
      if (allergenInfo != null) "allergen_info": allergenInfo,
      if (preparationTime != null) "preparation_time": preparationTime,
      if (category != null) "category": category,
      if (tags != null) "tags": tags,
      if (userFeedback != null) "user_feedback": userFeedback,
      if (lastUpdated != null) "last_updated": lastUpdated?.toIso8601String(),
      if (servings != null) "servings": servings,
    };
  }
  
  /// Create a copy of this Meal with optional new properties
  Meal copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? ingredients,
    List<String>? instructions,
    Map<String, double>? nutrients,
    String? imageUrl,
    List<String>? additionalImages,
    DateTime? createdAt,
    MealSource? source,
    bool? isFavorite,
    double? relevanceScore,
    String? notes,
    List<String>? allergenInfo,
    String? preparationTime,
    String? category,
    List<String>? tags,
    List<Map<String, dynamic>>? userFeedback,
    DateTime? lastUpdated,
    int? servings,
  }) {
    return Meal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      nutrients: nutrients ?? this.nutrients,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      isFavorite: isFavorite ?? this.isFavorite,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      notes: notes ?? this.notes,
      allergenInfo: allergenInfo ?? this.allergenInfo,
      preparationTime: preparationTime ?? this.preparationTime,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      userFeedback: userFeedback ?? this.userFeedback,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      servings: servings ?? this.servings,
    );
  }
}

/// Enum for meal sources
enum MealSource {
  /// AI-generated meal using OpenAI API
  openAi("openai"),
  
  /// AI-generated meal using Mistral API
  mistral("mistral"),
  
  /// Algorithmically generated meal using OpenFoodFacts data
  algorithmicOpenFoodFacts("algorithmic_off"),
  
  /// Individual product from OpenFoodFacts
  openFoodFactsProduct("off_product"),
  
  /// Static fallback meal
  fallbackStatic("fallback"),
  
  /// User-created meal
  userCreated("user"),
  
  /// Synthetic meal created from basic ingredient data
  synthetic("synthetic"),
  
  /// Unknown source
  unknown("unknown");
  
  /// String value for the enum
  final String value;
  
  /// Constructor
  const MealSource(this.value);
  
  /// Convert string to enum
  static MealSource fromString(String value) {
    return MealSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MealSource.unknown,
    );
  }
  
  @override
  String toString() => value;
}
