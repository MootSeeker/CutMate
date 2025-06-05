/// Model class for weight entry data
class WeightEntry {
  final DateTime date;
  final double weightKg;
  final String? notes;
  final String source; // 'manual' or device name

  WeightEntry({
    required this.date,
    required this.weightKg,
    this.notes,
    required this.source,
  });
  
  /// Create a weight entry from JSON data
  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: DateTime.parse(json['date']),
      weightKg: json['weight_kg'],
      notes: json['notes'],
      source: json['source'] ?? 'manual',
    );
  }
  
  /// Convert weight entry to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'weight_kg': weightKg,
      'notes': notes,
      'source': source,
    };
  }
}
