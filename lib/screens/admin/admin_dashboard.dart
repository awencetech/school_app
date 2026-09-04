import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/news_item.dart';
import '../../models/school_info.dart';
import '../../routes/app_routes.dart';
import '../../services/dummy_data_service.dart';
import '../../services/school_config_service.dart';
import '../../services/app_state.dart';
import '../../services/user_menu_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/cards/important_news_marquee.dart';
import '../../widgets/dashboard_extra_quick_access.dart';
import '../../widgets/dashboard_icon_grid.dart';
import '../../widgets/help_menu_screen.dart';
import '../../widgets/user_action_menu.dart';
import '../support/support_screen.dart';

/// Admin dashboard page matching the requested layout.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedBottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !context.watch<UserMenuState>().isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && context.read<UserMenuState>().isOpen) {
          context.read<UserMenuState>().close();
        }
      },
      child: Scaffold(
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
        body: Stack(
          children: [
            // Main body content
            _selectedBottomIndex == 2
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
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 12,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                height: 220,
                                child: () {
                                  final posterSource =
                                      config.posterDisplaySource;
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
                                            Container(
                                              color: const Color(0xFF1AA596),
                                            ),
                                        errorWidget: (context, url, error) {
                                          debugPrint(
                                            'School poster loading error: $error',
                                          );
                                          debugPrint(
                                            'Poster URL: $posterSource',
                                          );
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
                                    .map(
                                      (t) =>
                                          NewsItem(title: t, description: ''),
                                    )
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                              child: Text(
                                'Access frequently used features quickly',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: DashboardExtraQuickAccess(
                                crossAxisCount: 5,
                                appBarTitle: 'Quick Access',
                                leadingItems: [
                                  _QuickAction(
                                    icon: Icons.message,
                                    label: 'Messages HW, CW',
                                    color: Color(0xFFFF7043),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminQuickMessages,
                                    ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.calendar_month,
                                    label: 'Calendar',
                                    color: Color(0xFFE53935),
                                    onTap: () => Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.adminQuickCalendar),
                                  ),
                                  _QuickAction(
                                    icon: Icons.dashboard,
                                    label: 'Dashboard Summary Info',
                                    color: Color(0xFF1E4D8F),
                                    onTap: () =>
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.adminQuickDashboardSummary,
                                        ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.edit,
                                    label: 'Write Message',
                                    color: Color(0xFFBF360C),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminQuickWriteMessage,
                                    ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.assignment,
                                    label: 'Request',
                                    color: Color(0xFFF4B400),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminQuickRequest,
                                    ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.fact_check,
                                    label: 'Campaign Survey',
                                    color: Color(0xFF8D6E63),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminQuickGroupClass,
                                    ),
                                  ),
                                  _QuickAction(
                                    icon: Icons.assignment_turned_in,
                                    label: 'PTM',
                                    color: Color(0xFF5E7D1F),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminQuickPtm,
                                    ),
                                  ),
                                ],
                                onGroupClassBusTap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.adminQuickGroupsClassBus),
                                onCheckApproveTap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.adminQuickCheckApproval),
                                onUniRouteZ2Tap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.adminQuickTrackUniRoute),
                                onSp7Tap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.adminQuickTrackSp),
                                onTrackTap: () => Navigator.of(context)
                                    .pushNamed(AppRoutes.adminQuickTrack),
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
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminKnowYourSchoolWebsiteEdit,
                                    ),
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
                                    onTap: () =>
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.staffEventsCelebration,
                                        ),
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
                                    color: Color(0xFF388E3C),
                                  ),
                                  _SchoolLinkChip(
                                    icon: Icons.facebook,
                                    label: 'Facebook',
                                    color: Color(0xFF3B5998),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminKnowYourSchoolFacebookEdit,
                                    ),
                                  ),
                                  _SchoolLinkChip(
                                    icon: Icons.ondemand_video,
                                    label: 'Youtube',
                                    color: Color(0xFFD32F2F),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminKnowYourSchoolYoutubeEdit,
                                    ),
                                  ),
                                  _SchoolLinkChip(
                                    icon: Icons.chat,
                                    label: 'Whatsapp',
                                    color: Color(0xFF25D366),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminKnowYourSchoolWhatsappEdit,
                                    ),
                                  ),
                                  _SchoolLinkChip(
                                    icon: Icons.camera_alt,
                                    label: 'Instagram',
                                    color: Color(0xFFE1306C),
                                    onTap: () => Navigator.of(context).pushNamed(
                                      AppRoutes.adminKnowYourSchoolInstagramEdit,
                                    ),
                                  ),
                                  _SchoolLinkChip(
                                    icon: Icons.library_books,
                                    label: 'Library',
                                    color: Color(0xFF795548),
                                    onTap: () =>
                                        Navigator.of(context).pushNamed(
                                          AppRoutes.adminKnowYourSchoolLibraryEdit,
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
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.adminListClasses);
                                    },
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
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.adminWrite);
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.newspaper,
                                    label: 'School\nNews',
                                    color: Color(0xFF3B82F6),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.adminSchoolNews);
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.medical_services,
                                    label: 'Medical Event\nList',
                                    color: Color(0xFF92400E),
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.adminMedicalEventList,
                                      );
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.location_on,
                                    label: 'Track Bus\nGPS',
                                    color: Color(0xFF0EA5E9),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.adminTrackBusGps);
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.badge,
                                    label: 'Employee\nAttendance',
                                    color: Color(0xFF2563EB),
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.adminEmployeeAttendance,
                                      );
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.approval,
                                    label: 'Emp Leave\nApproval',
                                    color: Color(0xFF16A34A),
                                    onTap: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.adminEmpLeaveApproval,
                                      );
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.people_alt,
                                    label: 'One on\nOne',
                                    color: Color(0xFF4F46E5),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.adminOneOnOne);
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.door_front_door,
                                    label: 'Gate\nRegister',
                                    color: Color(0xFF10B981),
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed(AppRoutes.adminGateRegister);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            // Transparent overlay to close menu when tapping outside
            if (context.watch<UserMenuState>().isOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => context.read<UserMenuState>().close(),
                  child: Container(color: Colors.transparent),
                ),
              ),

            // User action menu (appears above the navigation bar)
            if (context.watch<UserMenuState>().isOpen)
              UserActionMenu(
                onProfileTap: () async {
                  context.read<UserMenuState>().close();
                  if (!mounted) return;
                  await Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminUserProfile);
                },
                onPasswordTap: () async {
                  context.read<UserMenuState>().close();
                  if (!mounted) return;
                  await Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminChangePassword);
                },
              ),
          ],
        ),
        bottomNavigationBar: AdminBottomNavigationBar(
          currentIndex: _selectedBottomIndex,
          onItemSelected: (index) async {
            switch (index) {
              case 0:
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.adminDashboard,
                  (route) => false,
                );
                break;
              case 2:
                setState(() => _selectedBottomIndex = 2);
                break;
              case 3:
                setState(() => _selectedBottomIndex = 3);
                break;
            }
          },
        ),
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
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF222222),
              ),
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
          SizedBox(
            height: 45,
            child: Text(
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
          ),
        ],
      ),
    );
  }
}
