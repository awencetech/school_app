import 'preferences_service.dart';

class AuthHeaders {
  AuthHeaders._();

  static const _tokenKey = 'auth_user_token';

  static Future<Map<String, String>> json() async {
    final token = await PreferencesService.getString(_tokenKey);
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> bearer() async {
    final token = await PreferencesService.getString(_tokenKey);
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
