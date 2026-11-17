import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_app/models/main_page_info.dart';
import 'package:school_app/routes/app_routes.dart';
import 'package:school_app/screens/splash/splash_screen.dart';
import 'package:school_app/services/app_state.dart';
import 'package:school_app/services/main_page_info_repository.dart';
import 'package:school_app/services/splash_config_service.dart';
import 'package:school_app/theme/app_colors.dart';
import 'package:school_app/widgets/founder_splash_image.dart';

class _MemoryMainPageInfoRepository extends MainPageInfoRepository {
  @override
  Future<MainPageInfo> getMainPageInfo() async => const MainPageInfo();
}

void main() {
  testWidgets('splash shows the restored default branding and portrait frame', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    final splashConfig = SplashConfigService(
      repository: _MemoryMainPageInfoRepository(),
    );
    await Future.wait([appState.initialization, splashConfig.initialization]);
    addTearDown(appState.dispose);
    addTearDown(splashConfig.dispose);

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

    expect(find.text('Since 1995'), findsOneWidget);
    expect(find.text('MMHSS'), findsOneWidget);
    expect(
      find.text('Muthuthevar Mukkulathor Higher Secondary School'),
      findsOneWidget,
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      AppColors.primary,
    );

    final frame = tester.widget<DecoratedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is ShapeDecoration &&
            (widget.decoration as ShapeDecoration).shape is OvalBorder,
      ),
    );
    final frameDecoration = frame.decoration as ShapeDecoration;
    final frameShape = frameDecoration.shape as OvalBorder;
    expect(frameDecoration.color, const Color(0xFF0B2D70));
    expect(frameShape.side.color, const Color(0xFFD9B56A));

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      FounderSplashImage.localAssetPath,
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Language selection'), findsOneWidget);
  });

  testWidgets(
    'splash shows the local founder portrait when no remote image is set',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FounderSplashImage(imageBase64: null)),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as AssetImage).assetName,
        FounderSplashImage.localAssetPath,
      );
    },
  );

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
