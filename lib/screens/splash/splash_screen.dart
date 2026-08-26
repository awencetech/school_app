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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), _navigateNext);
    });
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    if (widget.targetRoute != null && widget.targetRoute != AppRoutes.splash) {
      Navigator.of(context).pushReplacementNamed(widget.targetRoute!);
      return;
    }

    final appState = context.read<AppState>();
    await appState.initialization;
    if (!mounted) return;

    final hasLanguage = appState.hasSelectedLanguage;
    Navigator.of(context).pushReplacementNamed(
      hasLanguage ? AppRoutes.main : AppRoutes.language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // image sizing is handled by `FounderSplashImage` for consistency with admin preview.

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: FutureBuilder<SchoolInfo>(
            future: DummyDataService.getSchoolInfo(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              final splashConfig = context.watch<SplashConfigService>();

              final titleText = splashConfig.title.isNotEmpty ? splashConfig.title : (info?.name ?? 'SCHOOL NAME');
              final subtitleText = splashConfig.subtitle.isNotEmpty ? splashConfig.subtitle : (info?.motto ?? 'Motto goes here');
              final sinceText = 'Since ${splashConfig.since ?? info?.since ?? '1987'}';

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Use shared FounderSplashImage to ensure consistent sizing and fit
                        // between Admin Preview and the actual splash screen.
                        // This displays the uploaded framed image unchanged.
                        Builder(builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: SizedBox(
                              child: Center(
                                child: FounderSplashImage(
                                  imageBase64: splashConfig.imageBase64,
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          sinceText,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 11,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          titleText,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.appTitle.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitleText,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        if ((splashConfig.quote ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"${splashConfig.quote}"',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.white.withValues(alpha: 0.95),
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
    );
  }
}
