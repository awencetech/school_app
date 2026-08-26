import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_item.dart';
import '../../models/group.dart';
import '../../models/school_info.dart';
import '../../routes/app_routes.dart';
import '../../services/dummy_data_service.dart';
import '../../services/school_config_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/cards/important_news_marquee.dart';
import '../support/support_screen.dart';
import '../messages/messages_page.dart';
import 'class_demography_page.dart';

/// Admin dashboard page matching the requested layout.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final int _selectedBottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(
          context.watch<SchoolConfigService>().schoolName,
          style: AppTextStyles.appTitle,
        ),
        automaticallyImplyLeading: false,
      ),
      body: _selectedBottomIndex == 3
          ? const SupportScreen()
          : FutureBuilder<SchoolInfo>(
              future: DummyDataService.getSchoolInfo(),
              builder: (context, snapshot) {
                final config = context.watch<SchoolConfigService>();
                final schoolName = config.schoolName.isNotEmpty
                    ? config.schoolName
                    : snapshot.data?.name ?? 'SCHOOL NAME';
                final welcomeText = config.welcome.isNotEmpty
                    ? config.welcome
                    : 'Welcome ${context.watch<AppState>().currentUserId ?? 'Admin'}';

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 220,
                          child: () {
                            final posterSource = config.posterDisplaySource;
                            if (posterSource != null &&
                                posterSource.isNotEmpty) {
                              final uri = Uri.tryParse(posterSource);
                              if (uri != null &&
                                  uri.hasScheme &&
                                  (uri.scheme == 'http' ||
                                      uri.scheme == 'https')) {
                                return CachedNetworkImage(
                                  imageUrl: posterSource,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) =>
                                      Container(color: const Color(0xFF1AA596)),
                                  errorWidget: (context, url, error) {
                                    debugPrint(
                                      'School poster loading error: $error',
                                    );
                                    debugPrint('Poster URL: $posterSource');
                                    return Container(
                                      color: const Color(0xFF1AA596),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'School Poster\n(W-1920 x H-1080)',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryText,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              return Image.memory(
                                base64Decode(posterSource),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF1AA596),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'School Poster\n(W-1920 x H-1080)',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }

                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: const Color(0xFF1AA596),
                              alignment: Alignment.center,
                              child: Text(
                                'School Poster\n(W-1920 x H-1080)',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            );
                          }(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        schoolName,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        welcomeText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: ImportantNewsMarquee(
                          items: config.runningItems
                              .map((t) => NewsItem(title: t, description: ''))
                              .toList(),
                          height: 54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Text(
                          'Quick Access',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.95,
                          children: [
                            const _QuickAction(
                              icon: Icons.visibility,
                              label: 'HW/CW\nView',
                              color: Color(0xFFEF4444),
                            ),
                            const _QuickAction(
                              icon: Icons.calendar_month,
                              label: 'Event\nCalendar',
                              color: Color(0xFFF97316),
                            ),
                            const _QuickAction(
                              icon: Icons.dashboard,
                              label: 'Dashboard',
                              color: Color(0xFF1E40AF),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MessagesPage(),
                                ),
                              ),
                              child: const _QuickAction(
                                icon: Icons.edit,
                                label: 'Write\nMessage',
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            const _QuickAction(
                              icon: Icons.send,
                              label: 'Emp Req\nMessage',
                              color: Color(0xFFF59E0B),
                            ),
                            const _QuickAction(
                              icon: Icons.meeting_room,
                              label: 'Meeting',
                              color: Color(0xFF9333EA),
                            ),
                            const _QuickAction(
                              icon: Icons.task_alt,
                              label: 'Staff To Do\nTasks',
                              color: Color(0xFF2563EB),
                            ),
                            const _QuickAction(
                              icon: Icons.event_available,
                              label: 'PTM\nStatus',
                              color: Color(0xFF15803D),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Text(
                          'Know your School',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: [
                            _SchoolLinkChip(
                              icon: Icons.language,
                              label: 'Website',
                              color: Color(0xFF4CAF50),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.school,
                              label: 'School\nHandbag',
                              color: Color(0xFFF59E0B),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.event,
                              label: 'Events\nCelebration',
                              color: Color(0xFFF44336),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.menu_book,
                              label: 'School\nResources',
                              color: Color(0xFF8D6E63),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.schedule,
                              label: 'Exam\nSchedule',
                              color: Color(0xFF2563EB),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.announcement,
                              label: 'Announcement',
                              color: Color(0xFF43A047),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.emoji_events,
                              label: 'Monthly\nTopper',
                              color: Color(0xFF6A1B9A),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.people,
                              label: 'Demography',
                              color: Color(0xFF388E3C),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClassDemographyPage(
                                    group: Group(
                                      id: 'NCC2022',
                                      name: 'NCC2022',
                                      year: '2026',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.camera_alt,
                              label: 'Instagram',
                              color: Color(0xFFE1306C),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.ondemand_video,
                              label: 'You tube',
                              color: Color(0xFFD32F2F),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              color: Color(0xFF3B5998),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.chat,
                              label: 'Watsapp',
                              color: Color(0xFF25D366),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Text(
                          'Other Options',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: [
                            _QuickAction(
                              icon: Icons.menu,
                              label: 'Other\nMenu',
                              color: Color(0xFFB91C1C),
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.adminOtherOptions);
                              },
                            ),
                            _QuickAction(
                              icon: Icons.group,
                              label: 'List\nStudents',
                              color: Color(0xFFF59E0B),
                            ),
                            _QuickAction(
                              icon: Icons.person,
                              label: 'List\nTeachers',
                              color: Color(0xFFF43F5E),
                            ),
                            _QuickAction(
                              icon: Icons.class_,
                              label: 'List\nClasses',
                              color: Color(0xFF16A34A),
                            ),
                            _QuickAction(
                              icon: Icons.group_work,
                              label: 'List Other\ngroups',
                              color: Color(0xFF7C3AED),
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.adminOtherGroups);
                              },
                            ),
                            _QuickAction(
                              icon: Icons.edit,
                              label: 'Write',
                              color: Color(0xFFF97316),
                            ),
                            _QuickAction(
                              icon: Icons.newspaper,
                              label: 'School\nNews',
                              color: Color(0xFF3B82F6),
                            ),
                            _QuickAction(
                              icon: Icons.medical_services,
                              label: 'Medical',
                              color: Color(0xFF92400E),
                            ),
                            _QuickAction(
                              icon: Icons.how_to_reg,
                              label: 'Student\nAttendance',
                              color: Color(0xFF0EA5E9),
                            ),
                            _QuickAction(
                              icon: Icons.badge,
                              label: 'Employee\nAttendance',
                              color: Color(0xFF2563EB),
                            ),
                            _QuickAction(
                              icon: Icons.approval,
                              label: 'Emp Leave\nApproval',
                              color: Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
              break;
          }
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(icon, size: 12, color: AppColors.white),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolLinkChip extends StatelessWidget {
  const _SchoolLinkChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }
}
