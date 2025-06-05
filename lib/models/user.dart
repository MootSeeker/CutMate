/// Model class for user data
class User {
  final String id;
  final String? email;
  final DateTime? dateOfBirth;
  final double heightCm;
  final double? startingWeightKg;
  final double? targetWeightKg;
  final DateTime? targetDate;
  final List<String>? dietaryRestrictions;
  final Map<String, dynamic>? preferences;
  
  User({
    required this.id,
    this.email,
    this.dateOfBirth,
    required this.heightCm,
    this.startingWeightKg,
    this.targetWeightKg,
    this.targetDate,
    this.dietaryRestrictions,
    this.preferences,
  });
  
  /// Create a user from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      heightCm: json['height_cm'],
      startingWeightKg: json['starting_weight_kg'],
      targetWeightKg: json['target_weight_kg'],
      targetDate: json['target_date'] != null 
          ? DateTime.parse(json['target_date']) 
          : null,
      dietaryRestrictions: json['dietary_restrictions'] != null 
          ? List<String>.from(json['dietary_restrictions']) 
          : null,
      preferences: json['preferences'],
    );
  }
  
  /// Convert user to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'height_cm': heightCm,
      'starting_weight_kg': startingWeightKg,
      'target_weight_kg': targetWeightKg,
      'target_date': targetDate?.toIso8601String(),
      'dietary_restrictions': dietaryRestrictions,
      'preferences': preferences,
    };
  }
}
