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
  final DateTime timestamp;
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

  // --- FIX 1: Renamed from 'fromJson' to 'fromMap' ---
  factory FoodLogEntry.fromMap(Map<String, dynamic> map) {
    // Read the Timestamp from Firestore and convert to DateTime
    DateTime parsedTimestamp;
    if (map['timestamp'] is Timestamp) {
      parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      // Fallback if it's somehow still saved as a string (e.g., old data)
      parsedTimestamp = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now(); // Default fallback
    }

    return FoodLogEntry(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      fiber: map['fiber'] ?? 0,
      timestamp: parsedTimestamp, // Use the parsed DateTime
      healthScore: map['healthScore'] as int?,
      healthDescription: map['healthDescription'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }

  // --- FIX 2: Renamed to 'toMap' and saving as a Timestamp ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      // --- CRITICAL FIX: Save as a Firestore Timestamp object ---
      'timestamp': Timestamp.fromDate(timestamp),
      'healthScore': healthScore,
      'healthDescription': healthDescription,
      'imagePath': imagePath,
    };
  }
}