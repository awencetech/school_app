import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/dashboard_icon_grid.dart';

class KnowYourSchoolPage extends StatelessWidget {
  const KnowYourSchoolPage({super.key});

  final List<_SchoolTile> _tiles = const [
    _SchoolTile(icon: Icons.language, label: 'Website', color: Color(0xFF4CAF50), route: AppRoutes.adminKnowYourSchoolWebsiteEdit),
    _SchoolTile(icon: Icons.school, label: 'School handbook', color: Color(0xFFF59E0B), route: AppRoutes.adminKnowYourSchoolSchoolHandbookEdit),
    _SchoolTile(icon: Icons.event, label: 'Events Celebrations', color: Color(0xFFF44336), route: AppRoutes.adminKnowYourSchoolEventsCelebrationEdit),
    _SchoolTile(icon: Icons.folder_copy_outlined, label: 'School Res.', color: Color(0xFF8D6E63), route: AppRoutes.adminKnowYourSchoolSchoolResourcesEdit),
    _SchoolTile(icon: Icons.newspaper, label: 'Newsletter', color: Color(0xFF5C84C3), route: AppRoutes.adminKnowYourSchoolNewsletterEdit),
    _SchoolTile(icon: Icons.announcement, label: 'Announcement', color: Color(0xFF43A047), route: AppRoutes.adminKnowYourSchoolAnnouncementEdit),
    _SchoolTile(icon: Icons.people, label: 'Demography', color: Color(0xFF6A1B9A), route: AppRoutes.adminKnowYourSchoolDemographyEdit),
    _SchoolTile(icon: Icons.facebook, label: 'Facebook', color: Color(0xFF3B5998), route: AppRoutes.adminKnowYourSchoolFacebookEdit),
    _SchoolTile(icon: Icons.ondemand_video, label: 'Youtube', color: Color(0xFFD32F2F), route: AppRoutes.adminKnowYourSchoolYoutubeEdit),
    _SchoolTile(icon: Icons.chat, label: 'Whatsapp', color: Color(0xFF25D366), route: AppRoutes.adminKnowYourSchoolWhatsappEdit),
    _SchoolTile(icon: Icons.camera_alt, label: 'Instagram', color: Color(0xFFE1306C), route: AppRoutes.adminKnowYourSchoolInstagramEdit),
    _SchoolTile(icon: Icons.library_books, label: 'Library', color: Color(0xFF795548), route: AppRoutes.adminKnowYourSchoolLibraryEdit),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
        ),
        title: const Text('Know Your School'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Know your School',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              DashboardIconGrid(
                children: _tiles
                    .map(
                      (tile) => _SchoolLinkChip(
                        icon: tile.icon,
                        label: tile.label,
                        color: tile.color,
                        onTap: () => Navigator.of(context).pushNamed(tile.route),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
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

class _SchoolTile {
  const _SchoolTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
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
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
