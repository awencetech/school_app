import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for app settings.
class PreferencesService {
  PreferencesService._();

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }
}

