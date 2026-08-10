import 'package:flutter/foundation.dart';

import '../models/language_option.dart';
import 'preferences_service.dart';

/// Global app state (language + bottom navigation) backed by SharedPreferences.
class AppState extends ChangeNotifier {
  static const _languageKey = 'selected_language';
  static const _loggedInKey = 'user_logged_in';

  LanguageOption? _selectedLanguage;
  int _bottomNavIndex = 0;
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  late final Future<void> initialization;

  AppState() {
    initialization = _loadInitialState();
  }

  LanguageOption? get selectedLanguage => _selectedLanguage;

  int get bottomNavIndex => _bottomNavIndex;

  bool get isLoggedIn => _isLoggedIn;

  bool get isInitialized => _isInitialized;

  bool get hasSelectedLanguage => _selectedLanguage != null;

  Future<void> _loadInitialState() async {
    final savedLanguageCode = await PreferencesService.getString(_languageKey);
    final savedLoggedInState = await PreferencesService.getBool(_loggedInKey);
    _selectedLanguage = LanguageOptionX.fromCode(savedLanguageCode);
    _isLoggedIn = savedLoggedInState ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(LanguageOption language) async {
    _selectedLanguage = language;
    await PreferencesService.setString(_languageKey, language.code);
    notifyListeners();
  }

  Future<void> setLoggedIn(bool value) async {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    await PreferencesService.setBool(_loggedInKey, value);
    notifyListeners();
  }

  Future<void> logout() async {
    await setLoggedIn(false);
    setBottomNavIndex(0);
  }

  void setBottomNavIndex(int index) {
    if (_bottomNavIndex == index) return;
    _bottomNavIndex = index;
    notifyListeners();
  }
}

