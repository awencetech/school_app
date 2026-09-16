import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';

import 'generated/l10n/app_localizations.dart';
import 'models/language_option.dart';
import 'routes/app_router.dart';
import 'routes/app_routes.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_state.dart';
import 'services/app_route_observer.dart';
import 'services/school_config_service.dart';
import 'services/splash_config_service.dart';
import 'services/user_menu_state.dart';
import 'theme/app_theme.dart';

class _QuillLocalizationsDelegate extends LocalizationsDelegate<FlutterQuillLocalizations> {
  const _QuillLocalizationsDelegate();

  @override
  Future<FlutterQuillLocalizations> load(Locale locale) {
    final quillLocale = locale.languageCode == 'ta' ? const Locale('en') : locale;
    return FlutterQuillLocalizations.delegate.load(quillLocale);
  }

  @override
  bool isSupported(Locale locale) => const {'en', 'hi', 'ta'}.contains(locale.languageCode);

  @override
  bool shouldReload(_QuillLocalizationsDelegate old) => false;
}

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
      child: Consumer<AppState>(
        builder: (context, appState, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'School App',
          theme: AppTheme.light,
          locale: Locale(appState.selectedLanguage?.code ?? 'en'),
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            const _QuillLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
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
      ),
    );
  }
}

