import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/school_info.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/dummy_data_service.dart';
import '../../services/splash_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/founder_splash_image.dart';

/// Splash screen with founder image and school branding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.targetRoute});

  final String? targetRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 1), _navigateNext);
    });
  }

  Future<void> _navigateNext() async {
    // Prevent duplicate navigation calls
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    // If a specific target route was requested, navigate there directly
    if (widget.targetRoute != null && widget.targetRoute != AppRoutes.splash) {
      Navigator.of(context).pushReplacementNamed(widget.targetRoute!);
      return;
    }

    final appState = context.read<AppState>();

    // Wait for initialization with timeout protection
    try {
      await appState.initialization.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint(
            'WARNING: AppState initialization timeout. Proceeding with available data.',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'ERROR: Initialization error: $e. Proceeding with available data.',
      );
    }

    if (!mounted) return;

    // Navigation logic based on authentication and language state:
    // 1. If not logged in AND no language selected -> go to language selection
    // 2. If not logged in AND language selected -> go to login/main page
    // 3. If logged in AND no language selected -> go to language selection
    // 4. If logged in AND language selected -> go to main/dashboard

    final hasLanguage = appState.hasSelectedLanguage;
    final isLoggedIn = appState.isLoggedIn;

    late String nextRoute;
    if (!hasLanguage) {
      // User must select language first
      nextRoute = AppRoutes.language;
    } else if (!isLoggedIn) {
      // User is logged out, go to login/main page
      nextRoute = AppRoutes.main;
    } else {
      // User is logged in with language selected, go to main (which handles the dashboard routing)
      nextRoute = AppRoutes.main;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final horizontalPadding = isCompact ? 20.0 : 32.0;
              final verticalInset = isCompact ? 48.0 : 80.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isCompact ? 24 : 40,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - verticalInset)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: FutureBuilder<SchoolInfo>(
                        future: DummyDataService.getSchoolInfo(),
                        builder: (context, snapshot) {
                          final info = snapshot.data;
                          final splashConfig = context
                              .watch<SplashConfigService>();

                          final titleText = splashConfig.title.isNotEmpty
                              ? splashConfig.title
                              : (info?.name.isNotEmpty == true
                                    ? info!.name
                                    : 'MMHS');
                          final subtitleText = splashConfig.subtitle.isNotEmpty
                              ? splashConfig.subtitle
                              : (info?.motto ?? '');
                          final since = splashConfig.since.isNotEmpty
                              ? splashConfig.since
                              : (info?.since ?? '');

                          return Container(
                            padding: EdgeInsets.fromLTRB(
                              isCompact ? 20 : 40,
                              isCompact ? 24 : 36,
                              isCompact ? 20 : 40,
                              isCompact ? 26 : 38,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // The shared widget keeps the uploaded logo unchanged.
                                Container(
                                  padding: EdgeInsets.all(isCompact ? 12 : 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(
                                      alpha: 0.96,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: FounderSplashImage(
                                    imageBase64: splashConfig.imageBase64,
                                  ),
                                ),
                                if (since.isNotEmpty) ...[
                                  const SizedBox(height: 22),
                                  Text(
                                    'Since $since',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: isCompact ? 11 : 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                                SizedBox(height: isCompact ? 8 : 10),
                                Text(
                                  titleText,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.appTitle.copyWith(
                                    fontSize: isCompact ? 21 : 25,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (subtitleText.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    subtitleText,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: isCompact ? 12 : 13,
                                      color: AppColors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                                if (splashConfig.quote.trim().isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '"${splashConfig.quote}"',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: isCompact ? 12 : 13,
                                        color: AppColors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                        fontStyle: FontStyle.italic,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
