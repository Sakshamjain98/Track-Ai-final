// lib/features/home/models/food_log_entry.dart

class FoodLogEntry {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final DateTime timestamp;
  // --- ADD THESE ---
  final int? healthScore;
  final String? healthDescription;

  final String? imagePath; // Path to the saved image file  // ---------------

  FoodLogEntry({
    required this.id,
    required this.name,
    required this.calories,
    this.imagePath,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.timestamp,
    // --- ADD THESE ---
    this.healthScore,
    this.healthDescription,
    // ---------------
  });

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    return FoodLogEntry(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      fiber: json['fiber'] ?? 0,
      timestamp: DateTime.parse(json['timestamp']),
      // --- ADD THESE ---
      healthScore: json['healthScore'] as int?, // Allow null
      healthDescription: json['healthDescription'] as String?, // Allow null
      // ---------------
      imagePath: json['imagePath'] as String?, // Load the path
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'timestamp': timestamp.toIso8601String(),
      // --- ADD THESE ---
      'healthScore': healthScore,
      'healthDescription': healthDescription,
      // ---------------
      'imagePath': imagePath, // Save the path
    };
  }
}