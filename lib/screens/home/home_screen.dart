import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/school_info.dart';
import '../../services/app_state.dart';
import '../../services/dummy_data_service.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/images/school_poster.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.divider,
                    child: Center(
                      child: Text(
                        'School Poster',
                        style: AppTextStyles.subtitle
                            .copyWith(color: AppColors.hintText),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<SchoolInfo>(
            future: DummyDataService.getSchoolInfo(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    info?.name ?? 'SCHOOL NAME',
                    style: AppTextStyles.sectionTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info?.quote ??
                        'Every student has the potential to achieve greatness through dedication, discipline, and continuous learning.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF616161),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Important News',
                      style: AppTextStyles.sectionTitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ImportantNewsTicker(
                    items: [
                      'Sports Day Registrations Open',
                      'Admissions Open for 2026–27',
                      'Quarterly Exams Start on August 15',
                      'Parent–Teacher Meeting on Friday',
                      'Independence Day Celebration on August 15',
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome To ${info?.name ?? 'School Name'}',
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
                    onPressed: (info?.websiteUrl ?? '').isNotEmpty
                        ? () => _openWebsite(info!.websiteUrl)
                        : null,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          _NewsNote(
            title: 'School App',
            body:
                'Parents are requested to update their School app profile with appropriate data for effective communication. For app related queries contact school.',
          ),
          const SizedBox(height: 14),
          _NewsNote(
            title: 'Check Dashboard Frequently',
            body:
                'Parents are requested to check the Dashboard Summary Info TAB in School App frequently so all dues be updated with latest News and information about the School.',
          ),
          const SizedBox(height: 14),
          _NewsNote(
            title: 'Students are strictly prohibited to bring mobile phone',
            body:
                'Parents are hereby notified not to allow their ward to come to school with mobile phones, if students violate the ban and carry mobile phone with them, it will be confiscated and sent to be returned with notice.',
          ),
          const SizedBox(height: 14),
          _NewsNote(
            title: 'Lunch Time Notice',
            body:
                'We highly appreciate you to send a complete healthy Vegetarian (egg is permitted) lunch box for your kids. Bringing non-vegetarian food to the campus is highly prohibited as per the norms of the school.',
          ),
          const SizedBox(height: 14),
          _NewsNote(
            title: 'Bring Books as per Time table',
            body:
                'All students are expected to bring their books and notes according to their Class Timetable posted in the app.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NewsNote extends StatelessWidget {
  const _NewsNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

