import 'app_state.dart';

class LoginRoleValidation {
  const LoginRoleValidation._();

  static Future<String?> validateOrLogout({
    required String? role,
    required AppState appState,
    required Future<void> Function() signOut,
  }) async {
    final normalizedRole = AppState.normalizeSupportedRole(role);
    if (normalizedRole != null) return normalizedRole;

    await appState.logout();
    await signOut();
    return null;
  }
}
