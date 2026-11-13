import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/generated/l10n/app_localizations.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/screens/admin/splash_screen_editor.dart';
import 'package:school_app/screens/splash/splash_screen.dart';
import 'package:school_app/models/main_page_info.dart';
import 'package:school_app/services/main_page_info_repository.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/splash_config_service.dart';

class _MemorySplashRepository extends MainPageInfoRepository {
  SplashScreenModel _splashScreen = const SplashScreenModel();

  @override
  Future<MainPageInfo> getMainPageInfo() async {
    return MainPageInfo(splashScreen: _splashScreen);
  }

  @override
  Future<MainPageInfo> getSplashScreen() async {
    return MainPageInfo(splashScreen: _splashScreen);
  }

  @override
  Future<MainPageInfo> updateSplashScreen(Map<String, dynamic> payload) async {
    _splashScreen = SplashScreenModel.fromJson(payload);
    return MainPageInfo(splashScreen: _splashScreen);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash editor saves when optional Since is empty', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = SplashConfigService(repository: _MemorySplashRepository());
    await service.initialization;
    addTearDown(service.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SplashConfigService>.value(
        value: service,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreenEditor(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Title',
      ),
      'School title',
    );

    final sinceField = tester.widget<TextField>(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Since (year, optional)',
      ),
    );
    expect(sinceField.controller?.text, isEmpty);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(service.since, isEmpty);
    expect(find.text('Since '), findsNothing);
    expect(find.text('Splash screen updated successfully.'), findsOneWidget);
  });

  testWidgets('admin-saved Since appears on splash and clears when removed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _MemorySplashRepository();
    final service = SplashConfigService(repository: repository);
    final appState = AppState();
    await Future.wait([service.initialization, appState.initialization]);
    addTearDown(service.dispose);
    addTearDown(appState.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SplashConfigService>.value(
        value: service,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreenEditor(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Title',
      ),
      'School title',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Since (year, optional)',
      ),
      '1998',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.since, '1998');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SplashConfigService>.value(value: service),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.language: (_) =>
                const Scaffold(body: Text('Language selection')),
          },
          home: const SplashScreen(targetRoute: AppRoutes.language),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Since 1998'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider<SplashConfigService>.value(
        value: service,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreenEditor(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Since (year, optional)',
      ),
      '',
    );
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.since, isEmpty);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SplashConfigService>.value(value: service),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.language: (_) =>
                const Scaffold(body: Text('Language selection')),
          },
          home: const SplashScreen(targetRoute: AppRoutes.language),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Since'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Language selection'), findsOneWidget);
  });

  test('optional Since value saves, reloads, and clears', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = _MemorySplashRepository();
    final service = SplashConfigService(repository: repository);
    await service.initialization;
    addTearDown(service.dispose);

    expect(service.since, isEmpty);
    expect(await service.save(since: ''), isTrue);
    expect(service.since, isEmpty);

    expect(await service.save(since: '1998'), isTrue);
    expect(service.since, '1998');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('splash_since'), '1998');

    final restartedService = SplashConfigService(repository: repository);
    await restartedService.initialization;
    addTearDown(restartedService.dispose);
    expect(restartedService.since, '1998');

    expect(await restartedService.save(since: ''), isTrue);
    expect(restartedService.since, isEmpty);
    expect(preferences.getString('splash_since'), isEmpty);

    final reloadedService = SplashConfigService(repository: repository);
    await reloadedService.initialization;
    addTearDown(reloadedService.dispose);
    expect(reloadedService.since, isEmpty);
  });
}
