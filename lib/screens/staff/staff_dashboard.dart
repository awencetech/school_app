import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_item.dart';
import '../../routes/app_routes.dart';
import '../../services/school_config_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/cards/important_news_marquee.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../support/support_screen.dart';
import '../messages/messages_page.dart';

/// Staff dashboard screen matching the supplied design.
class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedBottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        centerTitle: true,
        title: Text(context.watch<SchoolConfigService>().schoolName, style: AppTextStyles.appTitle),
        automaticallyImplyLeading: false,
      ),
      body: _selectedBottomIndex == 3
          ? const SupportScreen()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    context.watch<SchoolConfigService>().schoolName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome Staff Name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (config.posterDisplaySource != null && config.posterDisplaySource!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: () {
                            final posterSource = config.posterDisplaySource!;
                            final uri = Uri.tryParse(posterSource);
                            if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
                              return CachedNetworkImage(
                                imageUrl: posterSource,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(
                                  color: AppColors.divider,
                                ),
                                errorWidget: (context, url, error) {
                                  debugPrint('School poster loading error: $error');
                                  debugPrint('Poster URL: $posterSource');
                                  return Container(
                                    color: AppColors.divider,
                                    child: const Center(child: Text('School Poster')),
                                  );
                                },
                              );
                            }
                            return Image.memory(
                              base64Decode(posterSource),
                              fit: BoxFit.contain,
                            );
                          }(),
                        ),
                      ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          icon: Icons.assessment,
                          label: 'Campaign\\nSurvey',
                          color: Color(0xFFFF7043),
                        ),
                        _QuickAction(
                          icon: Icons.calendar_month,
                          label: 'Event\\nCalendar',
                          color: Color(0xFFE53935),
                        ),
                        _QuickAction(
                          icon: Icons.dashboard,
                          label: 'Dashboard',
                          color: Color(0xFF1E4D8F),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MessagesPage()),
                          ),
                          child: const _QuickAction(
                            icon: Icons.edit,
                            label: 'Write\\nMessage',
                            color: Color(0xFFBF360C),
                          ),
                        ),
                        _QuickAction(
                          icon: Icons.send,
                          label: 'Request\\nMessage',
                          color: Color(0xFFF4B400),
                        ),
                        _QuickAction(
                          icon: Icons.table_chart,
                          label: 'Staff\\nTime Table',
                          color: Color(0xFF5C84C3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff Information',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 27,
                              backgroundColor: Colors.black,
                              child: Icon(
                                Icons.person,
                                size: 34,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Staff name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Staff ID',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF5F6368),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.82,
                            children: const [
                              _InfoChip(
                                icon: Icons.info,
                                label: 'Staff\\ninfo',
                                iconColor: Color(0xFF22C8C8),
                              ),
                              _InfoChip(
                                icon: Icons.beach_access,
                                label: 'Apply leave\\nManage Leave',
                                iconColor: Color(0xFFF57C00),
                              ),
                              _InfoChip(
                                icon: Icons.swipe,
                                label: 'Swipe\\nAttendance',
                                iconColor: Color(0xFF2E7D32),
                              ),
                              _InfoChip(
                                icon: Icons.feedback,
                                label: 'Management\\nFeedback',
                                iconColor: Color(0xFF1E88E5),
                              ),
                              _InfoChip(
                                icon: Icons.meeting_room,
                                label: 'Meeting',
                                iconColor: Color(0xFFD32F2F),
                              ),
                              _InfoChip(
                                icon: Icons.folder,
                                label: 'Staff\\nResources',
                                iconColor: Color(0xFF8D6E63),
                              ),
                              _InfoChip(
                                icon: Icons.menu_book,
                                label: 'Staff\\nHandbag',
                                iconColor: Color(0xFFF4B400),
                              ),
                              _InfoChip(
                                icon: Icons.task,
                                label: 'To Do\\nTasks',
                                iconColor: Color(0xFF0288D1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Classes/Groups',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Grade 10 C - 2026-27',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF222222),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const _ClassAction(
                                    icon: Icons.message,
                                    label: 'Write Group\\nMessages',
                                    color: Color(0xFF4CAF50),
                                  ),
                                  const _ClassAction(
                                    icon: Icons.upload_file,
                                    label: 'Upload\\nHW,CW',
                                    color: Color(0xFFD32F2F),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.studentMoreOptions,
                                    ),
                                    child: const _ClassAction(
                                      icon: Icons.more_horiz,
                                      label: 'More\\nOptions',
                                      color: Color(0xFF1976D2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Know your School',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: const [
                            _SchoolLinkChip(
                              icon: Icons.language,
                              label: 'Website',
                              color: Color(0xFF4CAF50),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.school,
                              label: 'School\\nHandbag',
                              color: Color(0xFFFFC107),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.event,
                              label: 'Events\\nCelebration',
                              color: Color(0xFFF44336),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.menu_book,
                              label: 'School\\nResources',
                              color: Color(0xFF8D6E63),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.schedule,
                              label: 'Exam\\nSchedule',
                              color: Color(0xFF1976D2),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.announcement,
                              label: 'Announcement',
                              color: Color(0xFF43A047),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.emoji_events,
                              label: 'Monthly\\nTopper',
                              color: Color(0xFF6A1B9A),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.people,
                              label: 'Demography',
                              color: Color(0xFF388E3C),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onItemSelected: (index) {
          if (index == 4) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.main,
              (route) => false,
            );
            return;
          }

          setState(() {
            _selectedBottomIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(
            icon,
            size: 12,
            color: AppColors.white,
          ),
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
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Icon(
            icon,
            size: 13,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

class _ClassAction extends StatelessWidget {
  const _ClassAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

class _SchoolLinkChip extends StatelessWidget {
  const _SchoolLinkChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.white,
          ),
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
    );
  }
}
