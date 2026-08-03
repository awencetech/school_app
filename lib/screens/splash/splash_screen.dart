import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/school_info.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/dummy_data_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Splash screen with founder image and school branding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final hasLanguage = context.read<AppState>().hasSelectedLanguage;
    Navigator.of(context).pushReplacementNamed(
      hasLanguage ? AppRoutes.main : AppRoutes.language,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FutureBuilder<SchoolInfo>(
              future: DummyDataService.getSchoolInfo(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 132,
                      width: 132,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.goldBorder, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/founder.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primaryDark,
                              child: const Icon(
                                Icons.person,
                                color: AppColors.white,
                                size: 56,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Since ${info?.since ?? '1987'}',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(info?.name ?? 'SCHOOL NAME', style: AppTextStyles.appTitle),
                    const SizedBox(height: 6),
                    Text(
                      info?.motto ?? 'Motto goes here',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
