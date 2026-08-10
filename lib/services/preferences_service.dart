import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight wrapper around SharedPreferences for app settings.
class PreferencesService {
  PreferencesService._();

  static const int _maxStoredValueLength = 256 * 1024;

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<String?> getString(String key) async {
    try {
      final prefs = await _prefs;
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setString(String key, String value) async {
    if (value.length > _maxStoredValueLength) {
      return;
    }

    try {
      final prefs = await _prefs;
      await prefs.setString(key, value);
    } catch (_) {
      // Ignore browser quota failures for large base64 payloads.
    }
  }

  static Future<bool?> getBool(String key) async {
    try {
      final prefs = await _prefs;
      return prefs.getBool(key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setBool(String key, bool value) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(key, value);
    } catch (_) {
      // Ignore browser storage failures.
    }
  }
}

