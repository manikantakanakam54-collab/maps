import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _favoritesKey = 'lpu_maps_favorites';
  static const String _darkModeKey = 'lpu_maps_dark_mode';
  static const String _voiceKey = 'lpu_maps_voice_enabled';
  static const String _recentSearchesKey = 'lpu_maps_recent_searches';
  static const String _mapStyleKey = 'lpu_maps_map_style';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // Favorites
  Set<String> getFavorites() {
    final list = _prefs.getStringList(_favoritesKey) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(String placeName) async {
    final favorites = getFavorites();
    if (favorites.contains(placeName)) {
      favorites.remove(placeName);
    } else {
      favorites.add(placeName);
    }
    await _prefs.setStringList(_favoritesKey, favorites.toList());
  }

  bool isFavorite(String placeName) {
    return getFavorites().contains(placeName);
  }

  // Theme Mode
  ThemeMode getThemeMode() {
    final mode = _prefs.getString(_darkModeKey);
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await _prefs.setString(_darkModeKey, val);
  }

  // Voice Guidance Enabled
  bool isVoiceEnabled() {
    return _prefs.getBool(_voiceKey) ?? true;
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    await _prefs.setBool(_voiceKey, enabled);
  }

  // Recent Searches
  List<String> getRecentSearches() {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final list = getRecentSearches();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 8) {
      list.removeRange(8, list.length);
    }
    await _prefs.setStringList(_recentSearchesKey, list);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }

  // Map Style
  String getMapStyle() {
    return _prefs.getString(_mapStyleKey) ?? 'google_hybrid';
  }

  Future<void> setMapStyle(String style) async {
    await _prefs.setString(_mapStyleKey, style);
  }
}
