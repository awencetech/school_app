import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/language_option.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/safe_image_helper.dart';
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
          AppLocalizations.of(context).schoolPoster,
          style: AppTextStyles.subtitle.copyWith(color: AppColors.hintText),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, String? posterSource) {
    return SafeImageHelper.buildImage(
      source: posterSource,
      fit: BoxFit.cover,
      fallback: _languagePosterPlaceholder(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();
    return Scaffold(
      appBar: CustomAppBar(title: config.schoolName),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Consumer<AppState>(
                    builder: (context, state, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context).selectPreferredLanguage,
                            style: AppTextStyles.languageTitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: _buildPoster(
                              context,
                              config.posterDisplaySource,
                            ),
                          ),
                          const SizedBox(height: 20),
                          LanguageCard(
                            label: LanguageOption.tamil.label,
                            iconColor: AppColors.tamilIcon,
                            selected:
                                state.selectedLanguage == LanguageOption.tamil,
                            onTap: () => state.setLanguage(LanguageOption.tamil),
                          ),
                          const SizedBox(height: 12),
                          LanguageCard(
                            label: LanguageOption.english.label,
                            iconColor: AppColors.englishIcon,
                            selected:
                                state.selectedLanguage == LanguageOption.english,
                            onTap: () => state.setLanguage(LanguageOption.english),
                          ),
                          const SizedBox(height: 12),
                          LanguageCard(
                            label: LanguageOption.hindi.label,
                            iconColor: AppColors.hindiIcon,
                            selected:
                                state.selectedLanguage == LanguageOption.hindi,
                            onTap: () => state.setLanguage(LanguageOption.hindi),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: AppLocalizations.of(context).continueText,
                            backgroundColor: AppColors.primary,
                            textColor: AppColors.white,
                            height: 48,
                            borderRadius: 6,
                            onPressed: state.hasSelectedLanguage
                                ? () => Navigator.of(
                                    context,
                                  ).pushReplacementNamed(AppRoutes.main)
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
