import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/screens/splash/splash_screen.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/splash_config_service.dart';
import 'package:school_app/theme/app_colors.dart';

void main() {
  testWidgets('splash content adapts without overflow across screen sizes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'splash_title': 'School Title',
      'splash_subtitle': 'Learning together',
      'splash_since': '1987',
      'splash_quote': 'A school quote',
    });

    final appState = AppState();
    await appState.initialization;
    addTearDown(appState.dispose);
    final splashConfig = SplashConfigService();
    addTearDown(splashConfig.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const sizes = [
      Size(375, 812),
      Size(768, 1024),
      Size(1440, 900),
      Size(812, 375),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: appState),
          ChangeNotifierProvider<SplashConfigService>.value(
            value: splashConfig,
          ),
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

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      AppColors.primary,
    );

    for (final size in sizes) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull, reason: 'Viewport $size');
      expect(find.text('School Title'), findsOneWidget);
      expect(find.text('Learning together'), findsOneWidget);
      expect(find.text('Since 1987'), findsOneWidget);
      expect(find.text('"A school quote"'), findsOneWidget);
    }

    splashConfig.since = '';
    splashConfig.notifyListeners();
    await tester.pump();
    expect(find.text('Since 1987'), findsNothing);
    expect(find.text('Since '), findsNothing);

    splashConfig.since = '2001';
    splashConfig.notifyListeners();
    await tester.pump();
    expect(find.text('Since 2001'), findsOneWidget);

    splashConfig.since = '';
    splashConfig.notifyListeners();
    await tester.pump();
    expect(find.text('Since 2001'), findsNothing);

    splashConfig.since = '   ';
    splashConfig.notifyListeners();
    await tester.pump();
    expect(find.textContaining('Since'), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Language selection'), findsOneWidget);
  });
}
