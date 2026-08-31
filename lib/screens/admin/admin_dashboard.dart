import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_item.dart';
import '../../models/school_info.dart';
import '../../routes/app_routes.dart';
import '../../services/dummy_data_service.dart';
import '../../services/school_config_service.dart';
import '../../services/social_url_service.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/cards/important_news_marquee.dart';
import '../../widgets/dashboard_extra_quick_access.dart';
import '../../widgets/dashboard_icon_grid.dart';
import '../../widgets/user_action_popup.dart';
import '../../widgets/help_menu_screen.dart';
import '../messages/messages_page.dart';
import '../support/support_screen.dart';
import '../staff/staff_campaigns_page.dart';
import '../staff/staff_request_message_page.dart';
import '../staff/staff_write_message_page.dart';
import '../student/student_check_approve_page.dart';
import '../student/student_group_class_bus_page.dart';
import '../student/student_ptm_page.dart';
import '../student/student_uni_route_page.dart';

/// Admin dashboard page matching the requested layout.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedBottomIndex = 0;

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

  Future<void> _openFacebook(BuildContext context) async {
    try {
      final url = await SocialUrlService().getFacebookUrl();
      if (!context.mounted) return;
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facebook link is not available.')));
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || !['http', 'https'].contains(uri.scheme.toLowerCase()) || uri.host.isEmpty || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open Facebook link.')));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open Facebook link.')));
    }
  }

  Future<void> _openYoutube(BuildContext context) async {
    try {
      final url = await SocialUrlService().getYoutubeUrl();
      if (!context.mounted) return;
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('YouTube link is not available.')));
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || !['http', 'https'].contains(uri.scheme.toLowerCase()) || uri.host.isEmpty || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open YouTube link.')));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open YouTube link.')));
    }
  }

  Future<void> _openInstagram(BuildContext context) async {
    try {
      final url = await SocialUrlService().getInstagramUrl();
      if (!context.mounted) return;
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Instagram link is not available.')));
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || !['http', 'https'].contains(uri.scheme.toLowerCase()) || uri.host.isEmpty || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open Instagram link.')));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open Instagram link.')));
    }
  }

  Future<void> _openWhatsapp(BuildContext context) async {
    try {
      final config = await SocialUrlService().getWhatsappConfig();
      if (!context.mounted) return;
      final number = (config['phoneNumber'] ?? '').replaceAll(RegExp(r'[^0-9]'), '');
      final message = config['text'] ?? '';
      if (number.isEmpty || message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp link is not available.')));
        return;
      }
      final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
    }
  }

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
        body: _selectedBottomIndex == 2
          ? const HelpMenuScreen()
          : _selectedBottomIndex == 3
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
                                        'School Poster\\n(W-1920 x H-1080)',
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
                                      'School Poster\\n(W-1920 x H-1080)',
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
                                'School Poster\\n(W-1920 x H-1080)',
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
                        child: DashboardExtraQuickAccess(
                          crossAxisCount: 5,
                          leadingItems: [
                            _QuickAction(
                              icon: Icons.message,
                              label: 'Messages HW, CW',
                              color: Color(0xFFFF7043),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MessagesPage(),
                                ),
                              ),
                            ),
                            _QuickAction(
                              icon: Icons.calendar_month,
                              label: 'Calendar',
                              color: Color(0xFFE53935),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.staffEventCalendar),
                            ),
                            _QuickAction(
                              icon: Icons.dashboard,
                              label: 'Dashboard Summary Info',
                              color: Color(0xFF1E4D8F),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.staffOverviewDashboard),
                            ),
                            _QuickAction(
                              icon: Icons.edit,
                              label: 'Write Message',
                              color: Color(0xFFBF360C),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const StaffWriteMessagePage(),
                                ),
                              ),
                            ),
                            _QuickAction(
                              icon: Icons.assignment,
                              label: 'Request',
                              color: Color(0xFFF4B400),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const StaffRequestMessagePage(),
                                ),
                              ),
                            ),
                            _QuickAction(
                              icon: Icons.fact_check,
                              label: 'Campaign Survey',
                              color: Color(0xFF8D6E63),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const StaffCampaignsPage(),
                                ),
                              ),
                            ),
                            _QuickAction(
                              icon: Icons.assignment_turned_in,
                              label: 'PTM',
                              color: Color(0xFF5E7D1F),
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
                        child: DashboardIconGrid(
                          children: [
                            _SchoolLinkChip(
                              icon: Icons.language,
                              label: 'Website',
                              color: Color(0xFF4CAF50),
                              onTap: () => _openWebsite(context),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.school,
                              label: 'School handbook',
                              color: Color(0xFFF59E0B),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.staffHandbook),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.event,
                              label: 'Events Celebrations',
                              color: Color(0xFFF44336),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.staffEventsCelebration),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.folder_copy_outlined,
                              label: 'School Res.',
                              color: Color(0xFF8D6E63),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.schoolResources),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.newspaper,
                              label: 'Newsletter',
                              color: Color(0xFF5C84C3),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.adminDashboardNewsletter),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.announcement,
                              label: 'Announcement',
                              color: Color(0xFF43A047),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.staffAnnouncements),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.people,
                              label: 'Demography',
                              color: Color(0xFF6A1B9A),
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.adminDashboardDemography,
                              ),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.facebook,
                              label: 'Facebook',
                              color: Color(0xFF3B5998),
                              onTap: () => _openFacebook(context),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.ondemand_video,
                              label: 'Youtube',
                              color: Color(0xFFD32F2F),
                              onTap: () => _openYoutube(context),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.chat,
                              label: 'Whatsapp',
                              color: Color(0xFF25D366),
                              onTap: () => _openWhatsapp(context),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.camera_alt,
                              label: 'Instagram',
                              color: Color(0xFFE1306C),
                              onTap: () => _openInstagram(context),
                            ),
                            _SchoolLinkChip(
                              icon: Icons.library_books,
                              label: 'Library',
                              color: Color(0xFF795548),
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.adminDashboardLibrary,
                              ),
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
                        child: DashboardIconGrid(
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
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.adminListStudents);
                              },
                            ),
                            _QuickAction(
                              icon: Icons.person,
                              label: 'List\nTeachers',
                              color: Color(0xFFF43F5E),
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.adminListTeachers);
                              },
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
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pushNamed(AppRoutes.adminDashboardNewsletter);
                              },
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
        onItemSelected: (index) async {
          if (index == 1 && context.read<AppState>().isLoggedIn) {
            showUserActionPopup(context);
            return;
          }

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
              setState(() => _selectedBottomIndex = 2);
              break;
            case 3:
              setState(() => _selectedBottomIndex = 3);
              break;
            case 4:
              await context.read<AppState>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: 3),
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
            child: Icon(icon, size: 16, color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
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
