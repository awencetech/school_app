import 'package:flutter/foundation.dart';

import '../models/language_option.dart';
import '../models/staff_access.dart';
import 'preferences_service.dart';
import 'staff_access_service.dart';

/// Global app state (language + bottom navigation) backed by SharedPreferences.
class AppState extends ChangeNotifier {
  static const supportedRoles = {'admin', 'staff', 'student'};

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
  Set<String>? _staffAccessGroups;
  List<String> _staffClassTeacherIds = const [];
  String? _staffAccessError;
  Future<void> _staffAccessInitialization = Future<void>.value();
  int _staffAccessGeneration = 0;
  bool _disposed = false;

  static Set<String>? cachedStaffAccessGroups;
  static String? cachedUserRole;

  late final Future<void> initialization;
  Future<void> get staffAccessInitialization => _staffAccessInitialization;
  List<String> get staffClassTeacherIds => _staffClassTeacherIds;
  String? get staffAccessError => _staffAccessError;

  AppState({StaffAccessService? staffAccessService})
    : _staffAccessService = staffAccessService ?? StaffAccessService() {
    initialization = _loadInitialState();
  }

  final StaffAccessService _staffAccessService;

  LanguageOption? get selectedLanguage => _selectedLanguage;

  int get bottomNavIndex => _bottomNavIndex;

  bool get isLoggedIn => _isLoggedIn;

  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserRole => _currentUserRole;
  String? get currentAuthToken => _currentAuthToken;
  Set<String>? get staffAccessGroups => _staffAccessGroups;

  bool get isInitialized => _isInitialized;

  bool get hasSelectedLanguage => _selectedLanguage != null;

  static String? normalizeSupportedRole(String? role) {
    final normalized = role?.trim().toLowerCase();
    return supportedRoles.contains(normalized) ? normalized : null;
  }

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
          ])
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // If loading takes too long, proceed with defaults
              debugPrint(
                'WARNING: AppState initialization timeout after 5 seconds. Using default values.',
              );
              return <dynamic>[null, null, null, null, null, null];
            },
          )
          .then((results) {
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
            cachedUserRole = savedRole;
          });
      _beginStaffAccessLoad();
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
    _isLoggedIn = false;
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserRole = null;
    _currentAuthToken = null;
    _staffAccessGroups = null;
    _staffClassTeacherIds = const [];
    _staffAccessError = null;
    _staffAccessGeneration++;
    _staffAccessInitialization = Future<void>.value();
    cachedStaffAccessGroups = null;
    cachedUserRole = null;
    await Future.wait([
      PreferencesService.setBool(_loggedInKey, false),
      PreferencesService.setString(_authUserIdKey, ''),
      PreferencesService.setString(_authEmailKey, ''),
      PreferencesService.setString(_authRoleKey, ''),
      PreferencesService.setString(_authTokenKey, ''),
    ]);
    setBottomNavIndex(0);
    notifyListeners();
  }

  Future<void> setAuthenticatedUser({
    required String userId,
    required String email,
    required String role,
    String? token,
  }) async {
    final normalizedRole = normalizeSupportedRole(role);
    if (normalizedRole == null) {
      throw ArgumentError.value(role, 'role', 'Unsupported user role.');
    }

    _currentUserId = userId;
    _currentUserEmail = email;
    _currentUserRole = normalizedRole;
    _currentAuthToken = token;
    cachedUserRole = normalizedRole;
    _staffAccessGroups = null;
    _staffClassTeacherIds = const [];
    _staffAccessError = null;
    _staffAccessGeneration++;
    _staffAccessInitialization = Future<void>.value();
    cachedStaffAccessGroups = null;
    await Future.wait([
      PreferencesService.setString(_authUserIdKey, userId),
      PreferencesService.setString(_authEmailKey, email),
      PreferencesService.setString(_authRoleKey, normalizedRole),
      PreferencesService.setString(_authTokenKey, token ?? ''),
    ]);
    await setLoggedIn(true);
    _beginStaffAccessLoad();
    notifyListeners();
  }

  void _beginStaffAccessLoad() {
    if (!_isLoggedIn ||
        (_currentUserRole ?? '').toLowerCase() != 'staff' ||
        (_currentAuthToken ?? '').isEmpty) {
      _staffAccessInitialization = Future<void>.value();
      return;
    }

    final generation = ++_staffAccessGeneration;
    _staffAccessInitialization = _loadStaffAccess(generation);
  }

  Future<void> _loadStaffAccess(int generation) async {
    try {
      final StaffAccessRecord access = await _staffAccessService.getMine();
      if (generation != _staffAccessGeneration || !_isLoggedIn) return;
      _staffAccessGroups = access.accessGroups.toSet();
      _staffClassTeacherIds = access.classTeacherIds;
      _staffAccessError = null;
      cachedStaffAccessGroups = _staffAccessGroups;
    } catch (error) {
      if (generation != _staffAccessGeneration) return;
      _staffAccessGroups = null;
      _staffClassTeacherIds = const [];
      _staffAccessError = 'Unable to load staff access.';
      cachedStaffAccessGroups = null;
      debugPrint('ERROR: Failed to load staff access (${error.runtimeType}).');
    } finally {
      if (generation == _staffAccessGeneration && !_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _staffAccessGeneration++;
    super.dispose();
  }

  static bool staffCanAccess(String group) {
    if ((cachedUserRole ?? '').toLowerCase() != 'staff' ||
        cachedStaffAccessGroups == null) {
      return true;
    }
    return cachedStaffAccessGroups!.contains(group);
  }

  void setBottomNavIndex(int index) {
    if (_bottomNavIndex == index) return;
    _bottomNavIndex = index;
    notifyListeners();
  }
}
