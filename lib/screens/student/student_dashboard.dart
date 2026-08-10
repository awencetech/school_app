import 'dart:convert';

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

/// Student dashboard screen following the supplied school ERP design system.
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
                    'Welcome Student Name',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Poster from school config (if set)
                  if (config.posterDisplaySource != null && config.posterDisplaySource!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _buildPosterWidget(config.posterDisplaySource!),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
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
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: 8,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final items = [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MessagesPage()),
                            ),
                            child: const _QuickAction(
                              icon: Icons.message,
                              label: 'Message\\nHW/CW',
                              color: Color(0xFFFF7043),
                            ),
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
                          _QuickAction(
                            icon: Icons.edit,
                            label: 'Write\\nMessage',
                            color: Color(0xFFBF360C),
                          ),
                          _QuickAction(
                            icon: Icons.assignment,
                            label: 'Request\\nMessage',
                            color: Color(0xFFF4B400),
                          ),
                          _QuickAction(
                            icon: Icons.fact_check,
                            label: 'Campaign\\nSurvey',
                            color: Color(0xFF8D6E63),
                          ),
                          _QuickAction(
                            icon: Icons.table_chart,
                            label: 'Class\\nTime Table',
                            color: Color(0xFF5C84C3),
                          ),
                          _QuickAction(
                            icon: Icons.assignment_turned_in,
                            label: 'PTM\\nStatus',
                            color: Color(0xFF5E7D1F),
                          ),
                        ];
                        return items[index];
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Information',
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
                                    'Student name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF222222),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Student ID',
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
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              final items = [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.studentInfo,
                                  ),
                                  child: const _InfoChip(
                                    icon: Icons.info,
                                    label: 'Student Info',
                                    iconColor: Color(0xFF22C8C8),
                                  ),
                                ),
                                const _InfoChip(
                                  icon: Icons.calendar_today,
                                  label: 'Attendance',
                                  iconColor: Color(0xFFF57C00),
                                ),
                                const _InfoChip(
                                  icon: Icons.bar_chart,
                                  label: 'Exam Results',
                                  iconColor: Color(0xFF2E7D32),
                                ),
                                const _InfoChip(
                                  icon: Icons.menu_book,
                                  label: 'Student Diary',
                                  iconColor: Color(0xFF26C6DA),
                                ),
                                const _InfoChip(
                                  icon: Icons.feedback,
                                  label: 'Faculty Feedback',
                                  iconColor: Color(0xFF1E88E5),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.studentMenu,
                                  ),
                                  child: const _InfoChip(
                                    icon: Icons.more_horiz,
                                    label: 'More Info',
                                    iconColor: Color(0xFFFF5252),
                                  ),
                                ),
                              ];
                              return items[index];
                            },
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
                        Row(
                          children: [
                            const Expanded(
                              child: _ClassTile(
                                icon: Icons.group,
                                label: 'Group/Class',
                                value: 'Grade 10 C',
                                color: Color(0xFF3B8E3C),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: _ClassTile(
                                icon: Icons.message,
                                label: 'HW/CW',
                                value: 'Messages',
                                color: Color(0xFFE64A19),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.studentMoreOptions,
                                ),
                                child: const _ClassTile(
                                  icon: Icons.more_horiz,
                                  label: 'More',
                                  value: 'Options',
                                  color: Color(0xFF607D8B),
                                ),
                              ),
                            ),
                          ],
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
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                          children: const [
                            _SchoolLinkTile(
                              icon: Icons.language,
                              label: 'Website',
                              color: Color(0xFF2E7D32),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.school,
                              label: 'School Handbook',
                              color: Color(0xFF1E4D8F),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.event,
                              label: 'Events Celebration',
                              color: Color(0xFFD32F2F),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.menu_book,
                              label: 'School Resources',
                              color: Color(0xFFB97A00),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.schedule,
                              label: 'Exam Schedule',
                              color: Color(0xFF5C84C3),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.announcement,
                              label: 'Announcement',
                              color: Color(0xFF795548),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.photo,
                              label: 'Monthly Topper',
                              color: Color(0xFF6A1B9A),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.camera,
                              label: 'Photography',
                              color: Color(0xFF00897B),
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

  Widget _buildPosterWidget(String posterSource) {
    final uri = Uri.tryParse(posterSource);
    if (uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        posterSource,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
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

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF5F6368),
          ),
        ),
      ],
    );
  }
}

class _SchoolLinkTile extends StatelessWidget {
  const _SchoolLinkTile({
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 16,
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
