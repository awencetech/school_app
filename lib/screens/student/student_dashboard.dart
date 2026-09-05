import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_item.dart';
import '../../models/group.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/school_config_service.dart';
import '../../services/social_url_service.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/cards/important_news_marquee.dart';
import '../../widgets/dashboard_bottom_nav.dart';
import '../../widgets/dashboard_extra_quick_access.dart';
import '../../widgets/dashboard_icon_grid.dart';
import '../../widgets/help_menu_screen.dart';
import '../support/support_screen.dart';
import '../messages/messages_page.dart';
import 'student_ptm_page.dart';
import 'student_group_class_bus_page.dart';
import 'student_check_approve_page.dart';
import 'student_uni_route_page.dart';
import '../staff/staff_campaigns_page.dart';
import '../staff/staff_request_message_page.dart';
import '../staff/staff_write_message_page.dart';
import '../admin/homework_today_in_class_page.dart';
import '../admin/class_demography_page.dart';

/// Student dashboard screen following the supplied school ERP design system.
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedBottomIndex = 0;
  String _studentName = 'Student name';
  String _studentId = '';
  String _studentImageUrl = '';
  bool _studentLoading = true;
  String? _studentError;

  Future<void> _openWebsite(BuildContext context) async {
    final websiteUrl = context.read<SchoolConfigService>().websiteUrl.trim();
    if (websiteUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School website is not configured yet.')),
      );
      return;
    }

    final uri = Uri.tryParse(websiteUrl);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School website URL is invalid.')),
      );
      return;
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the website right now.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStudentInformation();
  }

  Future<void> _loadStudentInformation() async {
    final appState = context.read<AppState>();
    try {
      await appState.initialization.timeout(const Duration(seconds: 6));
    } catch (_) {}
    if (!mounted) return;
    final userId = appState.currentUserId?.trim() ?? '';
    final token = appState.currentAuthToken?.trim() ?? '';
    if (userId.isEmpty || token.isEmpty) {
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        return;
      }
      return;
    }
    setState(() {
      _studentLoading = true;
      _studentError = null;
    });
    try {
      final student = await StudentService().getCurrentProfile(token: token);
      if (!mounted) return;
      setState(() {
        _studentName = student.name.isEmpty ? userId : student.name;
        _studentId = student.studentId.isEmpty ? userId : student.studentId;
        _studentImageUrl = student.imageUrl;
        _studentLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _studentLoading = false;
          _studentError = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Widget _studentPhoto() {
    const fallback = CircleAvatar(
      radius: 27,
      backgroundColor: Colors.black,
      child: Icon(Icons.person, size: 34, color: AppColors.white),
    );
    if (_studentImageUrl.isEmpty) {
      return fallback;
    }
    if (_studentImageUrl.startsWith('data:')) {
      try {
        final comma = _studentImageUrl.indexOf(',');
        if (comma < 0) return fallback;
        return CircleAvatar(
          radius: 27,
          backgroundImage: MemoryImage(
            base64Decode(_studentImageUrl.substring(comma + 1)),
          ),
        );
      } catch (_) {
        return fallback;
      }
    }
    final uri = Uri.tryParse(_studentImageUrl);
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme.toLowerCase()) ||
        uri.host.isEmpty) {
      return fallback;
    }
    return ClipOval(
      child: SizedBox(
        width: 54,
        height: 54,
        child: Image.network(
          _studentImageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }

  Future<void> _openNewsletter(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(AppRoutes.adminDashboardNewsletter);
  }

  Future<void> _openLibrary(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(AppRoutes.adminDashboardLibrary);
  }

  Future<void> _openSocialUrl(
    BuildContext context, {
    required Future<String> Function() fetcher,
    required String missingText,
    required String invalidText,
    required String openFailureText,
  }) async {
    try {
      final url = (await fetcher()).trim();
      if (url.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(missingText)));
        return;
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(invalidText)));
        return;
      }

      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(openFailureText)));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(openFailureText)));
    }
  }

  Future<void> _openFacebook(BuildContext context) => _openSocialUrl(
    context,
    fetcher: SocialUrlService().getFacebookUrl,
    missingText: 'Facebook link is not available.',
    invalidText: 'Facebook link is invalid.',
    openFailureText: 'Unable to open Facebook link.',
  );

  Future<void> _openYoutube(BuildContext context) => _openSocialUrl(
    context,
    fetcher: SocialUrlService().getYoutubeUrl,
    missingText: 'YouTube link is not available.',
    invalidText: 'YouTube link is invalid.',
    openFailureText: 'Unable to open YouTube link.',
  );

  Future<void> _openInstagram(BuildContext context) => _openSocialUrl(
    context,
    fetcher: SocialUrlService().getInstagramUrl,
    missingText: 'Instagram link is not available.',
    invalidText: 'Instagram link is invalid.',
    openFailureText: 'Unable to open Instagram link.',
  );

  Future<void> _openWhatsapp(BuildContext context) async {
    try {
      final config = await SocialUrlService().getWhatsappConfig();
      final phone = (config['phoneNumber'] ?? '').trim();
      if (phone.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp link is not available.')),
        );
        return;
      }

      final message = (config['text'] ?? '').trim();
      final uri = Uri.parse(
        'https://wa.me/$phone${message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}'}',
      );
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open WhatsApp.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
    }
  }

  Widget _studentQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String title,
    required String details,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _StudentQuickAccessDetailsPage(
                icon: icon,
                color: color,
                title: title,
                details: details,
              ),
            ),
          ),
      child: _QuickAction(icon: icon, label: label, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SchoolConfigService>();

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
      body: _selectedBottomIndex == 2
          ? const HelpMenuScreen()
          : _selectedBottomIndex == 3
          ? const SupportScreen()
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  // Poster from school config (if set)
                  if (config.posterDisplaySource != null &&
                      config.posterDisplaySource!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.zero,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _buildPosterWidget(config.posterDisplaySource!),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 4),
                  Text(
                    context.watch<SchoolConfigService>().schoolName,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome $_studentName',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
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
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Quick Access',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: DashboardExtraQuickAccess(
                      crossAxisCount: 5,
                      leadingItems: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MessagesPage(),
                            ),
                          ),
                          child: const _QuickAction(
                            icon: Icons.message,
                            label: 'Messages HW, CW',
                            color: Color(0xFFFF7043),
                          ),
                        ),
                        _studentQuickAction(
                          context,
                          icon: Icons.calendar_month,
                          label: 'Calendar',
                          color: Color(0xFFE53935),
                          title: 'Event Calendar',
                          details:
                              'View upcoming school events and important dates.',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.staffEventCalendar),
                        ),
                        _studentQuickAction(
                          context,
                          icon: Icons.dashboard,
                          label: 'Dashboard Summary Info',
                          color: Color(0xFF1E4D8F),
                          title: 'Student Dashboard',
                          details:
                              'Your student dashboard provides quick access to school activities, messages, and student information.',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.staffOverviewDashboard),
                        ),
                        _studentQuickAction(
                          context,
                          icon: Icons.edit,
                          label: 'Write Message',
                          color: Color(0xFFBF360C),
                          title: 'Write Message',
                          details:
                              'Create and send a message to your school or teachers.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StaffWriteMessagePage(),
                            ),
                          ),
                        ),
                        _studentQuickAction(
                          context,
                          icon: Icons.assignment,
                          label: 'Request',
                          color: Color(0xFFF4B400),
                          title: 'Request Message',
                          details: 'View and submit requests to the school.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StaffRequestMessagePage(),
                            ),
                          ),
                        ),
                        _studentQuickAction(
                          context,
                          icon: Icons.fact_check,
                          label: 'Campaign Survey',
                          color: Color(0xFF8D6E63),
                          title: 'Campaigns and Surveys',
                          details:
                              'Read active campaigns and surveys, then respond when required.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StaffCampaignsPage(),
                            ),
                          ),
                        ),
                        _studentQuickAction(
                          context,
                          icon: Icons.assignment_turned_in,
                          label: 'PTM',
                          color: Color(0xFF5E7D1F),
                          title: 'PTM Status',
                          details:
                              'Check parent-teacher meeting status and related updates.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StudentPtmPage(),
                            ),
                          ),
                        ),
                      ],
                      onGroupClassBusTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentGroupClassBusPage(),
                        ),
                      ),
                      onCheckApproveTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentCheckApprovePage(),
                        ),
                      ),
                      onUniRouteZ2Tap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentUniRoutePage(),
                        ),
                      ),
                      onSp7Tap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentUniRoutePage(
                            routeName: 'UNI-Route-SP7',
                          ),
                        ),
                      ),
                      onTrackTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const StudentUniRoutePage(routeName: 'Track'),
                        ),
                      ),
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
                        if (_studentLoading)
                          const SizedBox(
                            height: 54,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_studentError != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _studentError!,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ),
                              IconButton(
                                onPressed: _loadStudentInformation,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Retry',
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              _studentPhoto(),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _studentName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF222222),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      _studentId,
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
                          child: DashboardIconGrid.builder(
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              final items = [
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.studentDashboardInfo),
                                  child: const _InfoChip(
                                    icon: Icons.info,
                                    label: 'Student Info',
                                    iconColor: Color(0xFF22C8C8),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(
                                    AppRoutes.studentDashboardAttendance,
                                  ),
                                  child: const _InfoChip(
                                    icon: Icons.calendar_today,
                                    label: 'Attendance',
                                    iconColor: Color(0xFFF57C00),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(
                                    AppRoutes.studentDashboardExamResults,
                                  ),
                                  child: const _InfoChip(
                                    icon: Icons.bar_chart,
                                    label: 'Exam Results',
                                    iconColor: Color(0xFF2E7D32),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.studentDashboardDiary),
                                  child: const _InfoChip(
                                    icon: Icons.menu_book,
                                    label: 'Student Diary',
                                    iconColor: Color(0xFF26C6DA),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(
                                    AppRoutes.studentDashboardFacultyFeedback,
                                  ),
                                  child: const _InfoChip(
                                    icon: Icons.feedback,
                                    label: 'Faculty Feedback',
                                    iconColor: Color(0xFF1E88E5),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.studentDashboardMenu),
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
                        DashboardIconGrid(
                          children: [
                            const _ClassTile(
                              icon: Icons.group,
                              label: 'Group/Class',
                              value: 'Grade 10 C',
                              color: Color(0xFF3B8E3C),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const HomeworkTodayInClassPage(
                                        groupId: 'grade-10-c',
                                        groupName: '10 C',
                                        groupYear: '2026-27',
                                        initialTabIndex: 0,
                                      ),
                                ),
                              ),
                              child: const _ClassTile(
                                icon: Icons.message,
                                label: 'HW/CW',
                                value: 'Messages',
                                color: Color(0xFFE64A19),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.studentMoreOptions),
                              child: const _ClassTile(
                                icon: Icons.more_horiz,
                                label: 'More',
                                value: 'Options',
                                color: Color(0xFF607D8B),
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
                        DashboardIconGrid(
                          children: [
                            _SchoolLinkTile(
                              icon: Icons.language,
                              label: 'Website',
                              color: Color(0xFF2E7D32),
                              onTap: () => _openWebsite(context),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.school,
                              label: 'School handbook',
                              color: Color(0xFF1E4D8F),
                              routeName: AppRoutes.staffHandbook,
                            ),
                            _SchoolLinkTile(
                              icon: Icons.event,
                              label: 'Events Celebrations',
                              color: Color(0xFFD32F2F),
                              routeName: AppRoutes.staffEventsCelebration,
                            ),
                            _SchoolLinkTile(
                              icon: Icons.folder_copy_outlined,
                              label: 'School Res.',
                              color: Color(0xFFB97A00),
                              routeName: AppRoutes.schoolResources,
                            ),
                            _SchoolLinkTile(
                              icon: Icons.newspaper,
                              label: 'Newsletter',
                              color: Color(0xFF5C84C3),
                              onTap: () => _openNewsletter(context),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.announcement,
                              label: 'Announcement',
                              color: Color(0xFF795548),
                              routeName: AppRoutes.staffAnnouncements,
                            ),
                            _SchoolLinkTile(
                              icon: Icons.people,
                              label: 'Demography',
                              color: Color(0xFF6A1B9A),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ClassDemographyPage(
                                    group: Group(
                                      id: 'grade-10-c',
                                      name: 'Grade 10 C',
                                      year: '2026-27',
                                    ),
                                    isStaffView: true,
                                  ),
                                ),
                              ),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              color: Color(0xFF3B5998),
                              onTap: () => _openFacebook(context),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.ondemand_video,
                              label: 'Youtube',
                              color: Color(0xFFD32F2F),
                              onTap: () => _openYoutube(context),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.chat,
                              label: 'Whatsapp',
                              color: Color(0xFF25D366),
                              onTap: () => _openWhatsapp(context),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.camera_alt,
                              label: 'Instagram',
                              color: Color(0xFFE1306C),
                              onTap: () => _openInstagram(context),
                            ),
                            _SchoolLinkTile(
                              icon: Icons.library_books,
                              label: 'Library',
                              color: Color(0xFF795548),
                              onTap: () => _openLibrary(context),
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
        onItemSelected: (index) async {
          if (index == 4) {
            await context.read<AppState>().logout();
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
            return;
          }

          setState(() {
            _selectedBottomIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }

  Widget _buildPosterWidget(String posterSource) {
    final uri = Uri.tryParse(posterSource);
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImage(
        imageUrl: posterSource,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: AppColors.divider),
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

    return Image.memory(base64Decode(posterSource), fit: BoxFit.cover);
  }
}

class _StudentQuickAccessDetailsPage extends StatelessWidget {
  const _StudentQuickAccessDetailsPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.details,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String details;

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
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: AppColors.white, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              details,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ReusableBottomNavigationBar(
        currentIndex: 2,
        onItemSelected: (index) async {
          if (index == 4) {
            await context.read<AppState>().logout();
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Quick Menu',
          ),
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
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
    this.routeName,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? routeName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          onTap ??
          (routeName == null
              ? null
              : () => Navigator.of(context).pushNamed(routeName!)),
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
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
