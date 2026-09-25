// lib/core/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage and persist app-wide ThemeMode (Light vs Dark).
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _isInitialized;

  String get currentThemeDisplayName =>
      isDarkMode ? 'Dark Mode' : 'Light Mode';

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.light;
      }
    } catch (_) {
      _themeMode = ThemeMode.light;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change theme mode and persist choice to SharedPreferences.
  Future<void> setThemeMode(ThemeMode newMode) async {
    if (_themeMode == newMode) return;

    _themeMode = newMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        newMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  /// Toggle between Light and Dark mode.
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

