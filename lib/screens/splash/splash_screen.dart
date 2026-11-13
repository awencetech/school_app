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

    final appState = context.read<AppState>();

    // Let route authorization inspect a fully loaded authentication state.
    try {
      await appState.initialization.timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('ERROR: AppState initialization failed: $e');
    }

    if (!mounted) return;

    // If a specific target route was requested, navigate there directly
    if (widget.targetRoute != null && widget.targetRoute != AppRoutes.splash) {
      Navigator.of(context).pushReplacementNamed(widget.targetRoute!);
      return;
    }

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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SizedBox(
                width: double.infinity,
                child: FutureBuilder<SchoolInfo>(
                  future: DummyDataService.getSchoolInfo(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    final splashConfig = context.watch<SplashConfigService>();

                    final titleText = splashConfig.title.isNotEmpty
                        ? splashConfig.title
                        : (info?.name.isNotEmpty == true ? info!.name : 'MMHS');
                    final subtitleText = splashConfig.subtitle.isNotEmpty
                        ? splashConfig.subtitle
                        : (info?.motto ?? '');
                    final since = splashConfig.since.trim();

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: screenWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.08,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Center(
                                  child: FounderSplashImage(
                                    imageBase64: splashConfig.imageBase64,
                                  ),
                                ),
                              ),
                              if (since.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Since $since',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontSize: 11,
                                    color: AppColors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                titleText,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.appTitle.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (subtitleText.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  subtitleText,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    color: AppColors.white.withValues(
                                      alpha: 0.85,
                                    ),
                                  ),
                                ),
                              ],
                              if (splashConfig.quote.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '"${splashConfig.quote}"',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    color: AppColors.white.withValues(
                                      alpha: 0.95,
                                    ),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
