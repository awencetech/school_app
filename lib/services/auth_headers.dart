import 'preferences_service.dart';

class AuthHeaders {
  AuthHeaders._();

  static const _tokenKey = 'auth_user_token';

  static Future<String> _requiredToken() async {
    final token = (await PreferencesService.getString(_tokenKey))?.trim();
    if (token == null || token.isEmpty) {
      throw StateError(
        'Backend authentication token is unavailable. Please sign in again.',
      );
    }
    return token;
  }

  static Future<Map<String, String>> json() async {
    final token = (await PreferencesService.getString(_tokenKey))?.trim();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> bearer() async {
    final token = (await PreferencesService.getString(_tokenKey))?.trim();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> requiredJson() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _requiredToken()}',
  };

  static Future<Map<String, String>> requiredBearer() async => {
    'Authorization': 'Bearer ${await _requiredToken()}',
  };
}
