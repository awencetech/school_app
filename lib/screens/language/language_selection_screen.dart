import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/language_option.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/appbar/custom_app_bar.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/cards/language_card.dart';

/// Language selection screen shown on first launch.
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  Widget _languagePosterPlaceholder(BuildContext context) {
    return Container(
      color: AppColors.divider,
      child: Center(
        child: Text(
          'School Poster',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.hintText),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, String? posterSource) {
    if (posterSource != null && posterSource.isNotEmpty) {
      final uri = Uri.tryParse(posterSource);
      if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return CachedNetworkImage(
          imageUrl: posterSource,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(color: AppColors.divider),
          errorWidget: (context, url, error) {
            debugPrint('School poster loading error: $error');
            debugPrint('Poster URL: $posterSource');
            return _languagePosterPlaceholder(context);
          },
        );
      }

      return Image.memory(
        base64Decode(posterSource),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _languagePosterPlaceholder(context),
      );
    }

    return Image.asset(
      'assets/images/school_poster.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _languagePosterPlaceholder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();
    return Scaffold(
      appBar: CustomAppBar(title: config.schoolName),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Consumer<AppState>(
                builder: (context, state, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Select your preferred Language',
                        style: AppTextStyles.languageTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bannerWidth = constraints.maxWidth * 0.9;

                          return Center(
                            child: SizedBox(
                              width: bannerWidth,
                              height: 180,
                              child: _buildPoster(context, config.posterDisplaySource),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      LanguageCard(
                        label: LanguageOption.tamil.label,
                        iconColor: AppColors.tamilIcon,
                        selected: state.selectedLanguage == LanguageOption.tamil,
                        onTap: () => state.setLanguage(LanguageOption.tamil),
                      ),
                      const SizedBox(height: 12),
                      LanguageCard(
                        label: LanguageOption.english.label,
                        iconColor: AppColors.englishIcon,
                        selected: state.selectedLanguage == LanguageOption.english,
                        onTap: () => state.setLanguage(LanguageOption.english),
                      ),
                      const SizedBox(height: 12),
                      LanguageCard(
                        label: LanguageOption.hindi.label,
                        iconColor: AppColors.hindiIcon,
                        selected: state.selectedLanguage == LanguageOption.hindi,
                        onTap: () => state.setLanguage(LanguageOption.hindi),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Continue',
                        backgroundColor: AppColors.primary,
                        textColor: AppColors.white,
                        height: 48,
                        borderRadius: 6,
                        onPressed: state.hasSelectedLanguage
                            ? () => Navigator.of(context)
                                .pushReplacementNamed(AppRoutes.main)
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

