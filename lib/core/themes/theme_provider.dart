import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false; // Default to light mode
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> resetToDefault() async {
  _isDarkMode = false; // Reset to light mode
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_themeKey); // Remove the stored preference
  print('Reset theme to default: $_isDarkMode');
  notifyListeners();
}
  
  Future<void> _loadThemeFromPrefs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool('first_run') ?? true;
    
    if (isFirstRun) {
      // First run - set to light mode and mark first run as complete
      _isDarkMode = false;
      await prefs.setBool('first_run', false);
      await prefs.setBool(_themeKey, _isDarkMode);
      print('First run - set theme to: $_isDarkMode');
    } else {
      // Not first run - load saved preference
      final savedTheme = prefs.getBool(_themeKey);
      print('Loaded theme from prefs: $savedTheme');
      _isDarkMode = savedTheme ?? false;
    }
    
    print('Current theme mode: $_isDarkMode');
    notifyListeners();
  } catch (e) {
    print('Error loading theme: $e');
    _isDarkMode = false;
    notifyListeners();
  }
}
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    print('Toggled theme to: $_isDarkMode'); // Debug output
    notifyListeners();
  }
  
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      print('Set theme to: $_isDarkMode'); // Debug output
      notifyListeners();
    }
  }
}