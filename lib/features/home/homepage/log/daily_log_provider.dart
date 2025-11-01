// lib/features/home/providers/daily_log_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'food_log_entry.dart';

class DailyLogProvider with ChangeNotifier {
  List<FoodLogEntry> _entries = [];
  Map<String, num> _consumedTotals = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
    'fiber': 0,
  };

  List<FoodLogEntry> get entries => _entries;
  Map<String, num> get consumedTotals => _consumedTotals;

  // Constructor is now empty.
  // We will load data from the Homescreen's initState.
  DailyLogProvider();

  // REMOVED: checkDailyReset()
  // REMOVED: _loadLog()

  Future<void> addEntry(FoodLogEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Not logged in

    try {
      // --- FIX: Add directly to Firestore ---
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc('nutrition')
          .collection('entries')
          .doc(entry.id) // Use the entry's ID as the document ID
          .set(entry.toMap()); // Use the new toMap() method

      _entries.insert(0, entry); // Add to local list
      _recalculateTotals(); // Update local totals
      notifyListeners();
    } catch (e) {
      print("Error adding entry to Firestore: $e");
      // Optionally re-throw or show a user-facing error
    }
  }

  // Renamed from _calculateTotals to _recalculateTotals for clarity
  void _recalculateTotals() {
    _consumedTotals = {
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'fiber': 0.0,
    };

    // Sum all entries
    for (final entry in _entries) {
      _consumedTotals['calories'] = (_consumedTotals['calories'] ?? 0) + entry.calories;
      _consumedTotals['protein'] = (_consumedTotals['protein'] ?? 0) + entry.protein;
      _consumedTotals['carbs'] = (_consumedTotals['carbs'] ?? 0) + entry.carbs;
      _consumedTotals['fat'] = (_consumedTotals['fat'] ?? 0) + entry.fat;
      _consumedTotals['fiber'] = (_consumedTotals['fiber'] ?? 0) + entry.fiber;
    }
  }

  // This function is still needed for logout
  void clearLog() {
    _entries.clear();
    _consumedTotals = {
      'calories': 0.0,
      'protein': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'fiber': 0.0,
    };
    notifyListeners();
  }

  // This function is now the ONLY way to load data
  Future<void> loadEntriesForDate(DateTime date) async {
    // --- 1. CRITICAL: Clear old data first ---
    clearLog();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Not logged in

    try {
      // --- 2. Define date range for the query ---
      DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // --- 3. Fetch data from Firestore ---
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc('nutrition')
          .collection('entries')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .get();

      // --- 4. Process and add entries ---
      final List<FoodLogEntry> loadedEntries = [];
      for (var doc in querySnapshot.docs) {
        // --- FIX: Use fromMap ---
        loadedEntries.add(FoodLogEntry.fromMap(doc.data()));
      }

      _entries = loadedEntries;
      _recalculateTotals(); // Re-calculate totals based on loaded entries
    } catch (e) {
      print("Error loading log entries: $e");
    } finally {
      notifyListeners();
    }
  }

// REMOVED: _saveLog()
// REMOVED: _clearLog(SharedPreferences prefs, String today)
}