import 'package:flutter/foundation.dart';

import '../models/language_option.dart';
import 'preferences_service.dart';

/// Global app state (language + bottom navigation) backed by SharedPreferences.
class AppState extends ChangeNotifier {
  static const _languageKey = 'selected_language';
  static const _loggedInKey = 'user_logged_in';
  static const _authUserIdKey = 'auth_user_id';
  static const _authEmailKey = 'auth_user_email';
  static const _authRoleKey = 'auth_user_role';
  static const _authTokenKey = 'auth_user_token';

  LanguageOption? _selectedLanguage;
  int _bottomNavIndex = 0;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserRole;
  String? _currentAuthToken;

  late final Future<void> initialization;

  AppState() {
    initialization = _loadInitialState();
  }

  LanguageOption? get selectedLanguage => _selectedLanguage;

  int get bottomNavIndex => _bottomNavIndex;

  bool get isLoggedIn => _isLoggedIn;

  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserRole => _currentUserRole;
  String? get currentAuthToken => _currentAuthToken;

  bool get isInitialized => _isInitialized;

  bool get hasSelectedLanguage => _selectedLanguage != null;

  Future<void> _loadInitialState() async {
    try {
      // Add timeout protection to prevent splash screen from hanging indefinitely
      // if SharedPreferences or any other startup operation is slow
      await Future.wait([
        PreferencesService.getString(_languageKey),
        PreferencesService.getBool(_loggedInKey),
        PreferencesService.getString(_authUserIdKey),
        PreferencesService.getString(_authEmailKey),
        PreferencesService.getString(_authRoleKey),
        PreferencesService.getString(_authTokenKey),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // If loading takes too long, proceed with defaults
          debugPrint('WARNING: AppState initialization timeout after 5 seconds. Using default values.');
          return <dynamic>[null, null, null, null, null, null];
        },
      ).then((results) {
        if (results.isEmpty || results.length < 6) return;
        final savedLanguageCode = results[0] as String?;
        final savedLoggedInState = results[1] as bool?;
        final savedUserId = results[2] as String?;
        final savedEmail = results[3] as String?;
        final savedRole = results[4] as String?;
        final savedToken = results[5] as String?;
        
        _selectedLanguage = LanguageOptionX.fromCode(savedLanguageCode);
        _isLoggedIn = savedLoggedInState ?? false;
        _currentUserId = savedUserId;
        _currentUserEmail = savedEmail;
        _currentUserRole = savedRole;
        _currentAuthToken = savedToken;
      });
    } catch (e, stackTrace) {
      debugPrint('ERROR: Failed to load initial app state: $e\n$stackTrace');
      // Do NOT crash on startup error. Proceed with default values.
      _isLoggedIn = false;
      _selectedLanguage = null;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
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
    // Clear stored authenticated user info
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserRole = null;
    _currentAuthToken = null;
    await PreferencesService.setString(_authUserIdKey, '');
    await PreferencesService.setString(_authEmailKey, '');
    await PreferencesService.setString(_authRoleKey, '');
    await PreferencesService.setString(_authTokenKey, '');
    setBottomNavIndex(0);
  }

  Future<void> setAuthenticatedUser({required String userId, required String email, required String role, String? token}) async {
    _currentUserId = userId;
    _currentUserEmail = email;
    _currentUserRole = role;
    _currentAuthToken = token;
    await PreferencesService.setString(_authUserIdKey, userId);
    await PreferencesService.setString(_authEmailKey, email);
    await PreferencesService.setString(_authRoleKey, role);
    await PreferencesService.setString(_authTokenKey, token ?? '');
    await setLoggedIn(true);
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    if (_bottomNavIndex == index) return;
    _bottomNavIndex = index;
    notifyListeners();
  }
}

