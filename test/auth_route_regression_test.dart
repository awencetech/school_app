import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/routes/app_route_access_guard.dart';
import 'package:school_app/routes/app_router.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/login_role_validation.dart';

Future<AppState> _createAppState({String? role}) async {
  SharedPreferences.setMockInitialValues({});
  final appState = AppState();
  await appState.initialization;
  if (role != null) {
    await appState.setAuthenticatedUser(
      userId: 'fixture-user',
      email: 'fixture@example.test',
      role: role,
    );
  }
  return appState;
}

Widget _routeHarness(AppState appState, String initialRoute) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(
      initialRoute: initialRoute,
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AppRouteAccessGuard(
              allowedRoles: AppRouter.allowedRolesForRoute(settings.name),
              child: Scaffold(
                body: Center(
                  child: Text(
                    settings.name == AppRoutes.main &&
                            appState.bottomNavIndex == 4
                        ? 'Login'
                        : settings.name ?? 'Unknown route',
                  ),
                ),
              ),
            ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('unauthenticated initial dashboard route opens Login', (
    tester,
  ) async {
    final appState = await _createAppState();
    addTearDown(appState.dispose);

    await tester.pumpWidget(_routeHarness(appState, AppRoutes.adminDashboard));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(appState.isLoggedIn, isFalse);
    expect(appState.bottomNavIndex, 4);
  });

  testWidgets('authenticated Admin can open the Admin initial route', (
    tester,
  ) async {
    final appState = await _createAppState(role: 'admin');
    addTearDown(appState.dispose);

    await tester.pumpWidget(_routeHarness(appState, AppRoutes.adminDashboard));
    await tester.pumpAndSettle();

    expect(find.text(AppRoutes.adminDashboard), findsOneWidget);
  });

  testWidgets('authenticated Staff can open the Staff initial route', (
    tester,
  ) async {
    final appState = await _createAppState(role: 'staff');
    addTearDown(appState.dispose);

    await tester.pumpWidget(_routeHarness(appState, AppRoutes.staffDashboard));
    await tester.pumpAndSettle();

    expect(find.text(AppRoutes.staffDashboard), findsOneWidget);
  });

  testWidgets('authenticated Student can open the Student initial route', (
    tester,
  ) async {
    final appState = await _createAppState(role: 'student');
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      _routeHarness(appState, AppRoutes.studentDashboard),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppRoutes.studentDashboard), findsOneWidget);
  });

  testWidgets('cross-role dashboard request redirects to the own dashboard', (
    tester,
  ) async {
    final appState = await _createAppState(role: 'student');
    addTearDown(appState.dispose);

    await tester.pumpWidget(_routeHarness(appState, AppRoutes.adminDashboard));
    await tester.pumpAndSettle();

    expect(find.text(AppRoutes.studentDashboard), findsOneWidget);
    expect(find.text(AppRoutes.adminDashboard), findsNothing);
  });

  test(
    'unsupported email-login role clears the existing app session',
    () async {
      final appState = await _createAppState(role: 'staff');
      addTearDown(appState.dispose);
      var signOutCalls = 0;

      final role = await LoginRoleValidation.validateOrLogout(
        role: 'parent',
        appState: appState,
        signOut: () async => signOutCalls++,
      );
      final preferences = await SharedPreferences.getInstance();

      expect(role, isNull);
      expect(signOutCalls, 1);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.currentUserId, isNull);
      expect(appState.currentUserRole, isNull);
      expect(appState.currentAuthToken, isNull);
      expect(preferences.getBool('user_logged_in'), isFalse);
      expect(preferences.getString('auth_user_id'), '');
      expect(preferences.getString('auth_user_email'), '');
      expect(preferences.getString('auth_user_role'), '');
      expect(preferences.getString('auth_user_token'), '');
    },
  );

  test(
    'unsupported Google-login role clears the existing app session',
    () async {
      final appState = await _createAppState(role: 'admin');
      addTearDown(appState.dispose);
      var signOutCalls = 0;

      final role = await LoginRoleValidation.validateOrLogout(
        role: 'guardian',
        appState: appState,
        signOut: () async => signOutCalls++,
      );
      final preferences = await SharedPreferences.getInstance();

      expect(role, isNull);
      expect(signOutCalls, 1);
      expect(appState.isLoggedIn, isFalse);
      expect(appState.currentUserId, isNull);
      expect(appState.currentUserRole, isNull);
      expect(appState.currentAuthToken, isNull);
      expect(preferences.getBool('user_logged_in'), isFalse);
      expect(preferences.getString('auth_user_id'), '');
      expect(preferences.getString('auth_user_email'), '');
      expect(preferences.getString('auth_user_role'), '');
      expect(preferences.getString('auth_user_token'), '');
    },
  );
}
