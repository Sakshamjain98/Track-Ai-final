// lib/features/home/providers/daily_log_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'food_log_entry.dart'; // Add intl: ^0.18.1 to pubspec.yaml

class DailyLogProvider with ChangeNotifier {
  List<FoodLogEntry> _entries = [];
  Map<String, num> _consumedTotals = {
    'calories': 0,
    'protein': 0,
    'carbs': 0,
    'fat': 0,
    'fiber': 0,
  };

  static const String _logKey = 'daily_log';
  static const String _dateKey = 'log_date';

  List<FoodLogEntry> get entries => _entries;
  Map<String, num> get consumedTotals => _consumedTotals;

  DailyLogProvider() {
    _loadLog(); // Load log when the app starts
  }

  // This is the daily reset logic
  Future<void> checkDailyReset() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != today) {
      // It's a new day! Clear the log.
      await _clearLog(prefs, today);
    } else {
      // It's the same day, just load the log
      _loadLog();
    }
  }

  Future<void> _loadLog() async {
    final prefs = await SharedPreferences.getInstance();
    final logString = prefs.getString(_logKey);

    if (logString != null) {
      final List<dynamic> logData = json.decode(logString);
      _entries = logData.map((item) => FoodLogEntry.fromJson(item)).toList();
    } else {
      _entries = [];
    }
    _recalculateTotals();
    notifyListeners();
  }

  Future<void> addEntry(FoodLogEntry entry) async {
    _entries.insert(0, entry); // Add new item to the top
    _recalculateTotals();
    await _saveLog();
    notifyListeners();
  }

  void _recalculateTotals() {
    _consumedTotals = {
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
      'fiber': 0,
    };
    for (var entry in _entries) {
      _consumedTotals['calories'] = _consumedTotals['calories']! + entry.calories;
      _consumedTotals['protein'] = _consumedTotals['protein']! + entry.protein;
      _consumedTotals['carbs'] = _consumedTotals['carbs']! + entry.carbs;
      _consumedTotals['fat'] = _consumedTotals['fat']! + entry.fat;
      _consumedTotals['fiber'] = _consumedTotals['fiber']! + entry.fiber;
    }
  }

  Future<void> _saveLog() async {
    final prefs = await SharedPreferences.getInstance();
    final logString = json.encode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_logKey, logString);
  }

  Future<void> _clearLog(SharedPreferences prefs, String today) async {
    _entries = [];
    _recalculateTotals();
    await prefs.remove(_logKey);
    await prefs.setString(_dateKey, today); // Set the new date
    notifyListeners();
  }
}