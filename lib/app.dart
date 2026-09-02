import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_state.dart';
import 'services/app_route_observer.dart';
import 'services/school_config_service.dart';
import 'services/splash_config_service.dart';
import 'services/user_menu_state.dart';
import 'theme/app_theme.dart';

/// Root widget for the School App.
class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => SplashConfigService()),
        ChangeNotifierProvider(create: (_) => SchoolConfigService()),
        ChangeNotifierProvider(create: (_) => UserMenuState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'School App',
        theme: AppTheme.light,
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: [
          const Locale('en', 'US'),
        ],
        // Ensure splash screen is always shown first on initial app load
        // (including web refresh / deep links). The splash will receive the
        // originally requested route as `targetRoute` and navigate there
        // after the delay.
        initialRoute: AppRoutes.splash,
        onGenerateInitialRoutes: (initialRouteName) {
          AppRouter.markSplashShown();
          return [
            PageRouteBuilder(
              settings: RouteSettings(name: initialRouteName),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  SplashScreen(targetRoute: initialRouteName),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) => child,
            ),
          ];
        },
        onGenerateRoute: AppRouter.onGenerateRoute,
        navigatorObservers: [appRouteObserver],
      ),
    );
  }
}

