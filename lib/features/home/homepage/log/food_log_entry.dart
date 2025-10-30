// lib/features/home/models/food_log_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class FoodLogEntry {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int fiber;
  final DateTime timestamp; // Keep this as DateTime
  final int? healthScore;
  final String? healthDescription;
  final String? imagePath;

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
    this.healthScore,
    this.healthDescription,
  });

  // --- MODIFIED fromJson ---
  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    // Read the Timestamp from Firestore and convert to DateTime
    DateTime parsedTimestamp;
    if (json['timestamp'] is Timestamp) {
      parsedTimestamp = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      // Fallback if it's somehow still saved as a string (e.g., old data)
      parsedTimestamp = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now(); // Default fallback
    }

    return FoodLogEntry(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      fiber: json['fiber'] ?? 0,
      timestamp: parsedTimestamp, // Use the parsed DateTime
      healthScore: json['healthScore'] as int?,
      healthDescription: json['healthDescription'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  // --- MODIFIED toJson ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      // Save as Firestore Timestamp object
      'timestamp': timestamp.toIso8601String(), // <-- FIX: Save as a String      'healthScore': healthScore,
      'healthDescription': healthDescription,
      'imagePath': imagePath,
    };
  }
}