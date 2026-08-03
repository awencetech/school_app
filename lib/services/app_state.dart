import 'package:flutter/foundation.dart';

import '../models/language_option.dart';
import 'preferences_service.dart';

/// Global app state (language + bottom navigation) backed by SharedPreferences.
class AppState extends ChangeNotifier {
  static const _languageKey = 'selected_language';

  LanguageOption? _selectedLanguage;
  int _bottomNavIndex = 0;

  AppState() {
    _loadInitialState();
  }

  LanguageOption? get selectedLanguage => _selectedLanguage;

  int get bottomNavIndex => _bottomNavIndex;

  bool get hasSelectedLanguage => _selectedLanguage != null;

  Future<void> _loadInitialState() async {
    final savedLanguageCode = await PreferencesService.getString(_languageKey);
    _selectedLanguage = LanguageOptionX.fromCode(savedLanguageCode);
    notifyListeners();
  }

  Future<void> setLanguage(LanguageOption language) async {
    _selectedLanguage = language;
    await PreferencesService.setString(_languageKey, language.code);
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    if (_bottomNavIndex == index) return;
    _bottomNavIndex = index;
    notifyListeners();
  }
}

