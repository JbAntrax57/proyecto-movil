import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('es');

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'es';
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // Si hay error, mantener español por defecto
      _currentLocale = const Locale('es');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      _currentLocale = Locale(languageCode);
      notifyListeners();
    } catch (e) {
      // Manejar error
    }
  }

  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }

  List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'es', 'name': 'Español'},
      {'code': 'en', 'name': 'English'},
    ];
  }
}