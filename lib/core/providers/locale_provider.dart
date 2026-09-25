// lib/core/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage and persist app-wide language locale (English vs Urdu).
class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language_code';

  Locale _locale = const Locale('en');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isUrdu => _locale.languageCode == 'ur';
  bool get isInitialized => _isInitialized;

  String get currentLanguageDisplayName =>
      isUrdu ? 'اردو (Urdu)' : 'English';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'ur' || savedCode == 'en')) {
        _locale = Locale(savedCode);
      }
    } catch (_) {
      // Default to English if SharedPreferences fails
      _locale = const Locale('en');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Change application locale and persist choice to SharedPreferences.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (_) {}
  }

  /// Toggle between English and Urdu.
  Future<void> toggleLanguage() async {
    if (isUrdu) {
      await setLocale(const Locale('en'));
    } else {
      await setLocale(const Locale('ur'));
    }
  }
}

