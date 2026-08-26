import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/school_info.dart';
import '../../services/app_state.dart';
import '../../services/dummy_data_service.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import '../../widgets/important_news_ticker.dart';

/// Home tab screen containing school highlights and quick actions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openWebsite(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: () {
              final posterSource = context
                  .watch<SchoolConfigService>()
                  .posterDisplaySource;
              if (posterSource != null && posterSource.isNotEmpty) {
                final uri = Uri.tryParse(posterSource);
                if (uri != null &&
                    uri.hasScheme &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  return Image.network(
                    posterSource,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('School poster loading error: $error');
                      debugPrint('Poster URL: $posterSource');
                      return Container(
                        color: AppColors.divider,
                        child: Center(
                          child: Text(
                            'School Poster',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.hintText,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return Image.memory(
                  base64Decode(posterSource),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.divider,
                      child: Center(
                        child: Text(
                          'School Poster',
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.hintText,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              return Image.asset(
                'assets/images/school_poster.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.divider,
                    child: Center(
                      child: Text(
                        'School Poster',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.hintText,
                        ),
                      ),
                    ),
                  );
                },
              );
            }(),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<SchoolInfo>(
              future: DummyDataService.getSchoolInfo(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final config = context.watch<SchoolConfigService>();
                final displayName = config.schoolName.isNotEmpty
                    ? config.schoolName
                    : (info?.name ?? 'SCHOOL NAME');
                final displayQuote = config.quote.isNotEmpty
                    ? config.quote
                    : (info?.quote ??
                          'Every student has the potential to achieve greatness through dedication, discipline, and continuous learning.');
                final displayWelcome = config.welcome.isNotEmpty
                    ? config.welcome
                    : 'Welcome To ${displayName}';
                final website = config.websiteUrl.isNotEmpty
                    ? config.websiteUrl
                    : (info?.websiteUrl ?? '');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.sectionTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayQuote,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF616161),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ImportantNewsTicker(items: config.runningItems),
                    const SizedBox(height: 12),
                    Text(
                      displayWelcome,
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Sign In',
                      onPressed: () =>
                          context.read<AppState>().setBottomNavIndex(4),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'School Website',
                      onPressed: website.isNotEmpty
                          ? () => _openWebsite(website)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Builder(
            builder: (context) {
              final config = context.watch<SchoolConfigService>();
              final sections = config.homeContent;
              return sections.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < sections.length; i++) ...[
                          _NewsNote(
                            title: sections[i].title.isNotEmpty
                                ? sections[i].title
                                : sections[i].name,
                            body: sections[i].description,
                            imageData: sections[i].photoBase64,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NewsNote extends StatelessWidget {
  const _NewsNote({
    required this.title,
    required this.body,
    this.imageData = '',
  });

  final String title;
  final String body;
  final String imageData;

  Widget _buildImage(String imageData) {
    final trimmed = imageData.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.hardEdge,
        child: CachedNetworkImage(
          imageUrl: trimmed,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: AppColors.divider),
          errorWidget: (context, url, error) => Container(
            color: AppColors.divider,
            child: const Center(
              child: Icon(Icons.broken_image, color: AppColors.hintText),
            ),
          ),
        ),
      );
    }

    try {
      final normalized = trimmed.toLowerCase().startsWith('data:')
          ? trimmed
                .substring(trimmed.indexOf(',') + 1)
                .replaceAll(RegExp(r'\s+'), '')
          : trimmed.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64Decode(normalized);
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.memory(bytes, fit: BoxFit.cover),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageData.isNotEmpty) ...[
          _buildImage(imageData),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(body, style: AppTextStyles.body),
      ],
    );
  }
}
