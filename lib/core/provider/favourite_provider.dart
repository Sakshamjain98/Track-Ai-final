import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider extends ChangeNotifier {
  Set<String> _favoriteTrackers = <String>{};
  static const String _favoritesKey = 'favorite_trackers';

  Set<String> get favoriteTrackers => _favoriteTrackers;

  FavoritesProvider() {
    _loadFavorites();
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList(_favoritesKey) ?? [];
      _favoriteTrackers = favoritesList.toSet();
      notifyListeners();
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoriteTrackers.toList());
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Check if a tracker is favorite
  bool isFavorite(String trackerId) {
    return _favoriteTrackers.contains(trackerId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String trackerId) async {
    if (_favoriteTrackers.contains(trackerId)) {
      _favoriteTrackers.remove(trackerId);
    } else {
      _favoriteTrackers.add(trackerId);
    }
    
    notifyListeners();
    await _saveFavorites();
  }

  // Add to favorites
  Future<void> addFavorite(String trackerId) async {
    if (!_favoriteTrackers.contains(trackerId)) {
      _favoriteTrackers.add(trackerId);
      notifyListeners();
      await _saveFavorites();
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String trackerId) async {
    if (_favoriteTrackers.contains(trackerId)) {
      _favoriteTrackers.remove(trackerId);
      notifyListeners();
      await _saveFavorites();
    }
  }

  // Get count of favorites
  int get favoritesCount => _favoriteTrackers.length;

  // Clear all favorites
  Future<void> clearAllFavorites() async {
    _favoriteTrackers.clear();
    notifyListeners();
    await _saveFavorites();
  }
}