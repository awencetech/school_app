import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/generated/l10n/app_localizations.dart';
import 'package:school_app/models/group.dart';
import 'package:school_app/models/library_book.dart';
import 'package:school_app/routes/app_router.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/screens/admin/create_class_screen.dart';
import 'package:school_app/screens/admin/library_page.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/class_service.dart';
import 'package:school_app/services/library_service.dart';
import 'package:school_app/services/user_menu_state.dart';

Future<AppState> _createAppState(String role) async {
  SharedPreferences.setMockInitialValues({});
  final appState = AppState();
  await appState.initialization;
  await appState.setAuthenticatedUser(
    userId: 'fixture-$role',
    email: '$role@example.test',
    role: role,
  );
  return appState;
}

class _FixtureLibraryService extends LibraryService {
  @override
  Future<List<LibraryBook>> getBooks() async => const [];
}

class _FixtureClassService extends ClassService {
  @override
  Future<List<Group>> getClasses({
    bool refresh = false,
    String schoolId = 'default-school',
  }) async => [
    Group(id: 'G8', name: 'Grade 8', type: 'Class', year: '2026-27'),
  ];
}

Widget _navigationApp(AppState appState, String role) {
  AppRouter.markSplashShown();
  final dashboardRoute = AppRoutes.dashboardForRole(role)!;

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>.value(value: appState),
      ChangeNotifierProvider(create: (_) => UserMenuState()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppRoutes.openLibrary(
                context,
                arguments: _FixtureLibraryService(),
              ),
              child: const Text('Open Library'),
            ),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == dashboardRoute) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                Scaffold(body: Center(child: Text('$role Dashboard'))),
          );
        }
        return AppRouter.onGenerateRoute(settings);
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final role in ['student', 'staff', 'admin']) {
    testWidgets('$role Library Home and Back return to the $role dashboard', (
      tester,
    ) async {
      final appState = await _createAppState(role);
      addTearDown(appState.dispose);

      await tester.pumpWidget(_navigationApp(appState, role));
      await tester.tap(find.text('Open Library'));
      await tester.pumpAndSettle();

      expect(find.byType(LibraryPage), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Open Library'), findsOneWidget);

      await tester.tap(find.text('Open Library'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();
      expect(find.text('$role Dashboard'), findsOneWidget);
    });
  }

  testWidgets('Admin List Classes opens the existing class-management screen', (
    tester,
  ) async {
    final appState = await _createAppState('admin');
    addTearDown(appState.dispose);
    AppRouter.markSplashShown();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider(create: (_) => UserMenuState()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.adminListClasses,
                    arguments: _FixtureClassService(),
                  ),
                  child: const Text('List Classes'),
                ),
              ),
            ),
          ),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );

    await tester.tap(find.text('List Classes'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateClassesScreen), findsOneWidget);
    expect(find.text('Create Classes'), findsOneWidget);
    expect(find.textContaining('Grade 8'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('List Classes'), findsOneWidget);
  });
}
