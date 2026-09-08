import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

/// More options screen for the classes/groups section.
class StudentMoreOptionsScreen extends StatelessWidget {
  const StudentMoreOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: Text(
          'SCHOOL NAME',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '10 - C',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: Main',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Description: Grade 10 C - 2026-27',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Status: Active',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Year: 2026',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: 14,
                itemBuilder: (context, index) {
                  final items = [
                    const _MoreOptionTile(icon: Icons.info, label: 'Group Info', color: Color(0xFF2563EB)),
                    const _MoreOptionTile(icon: Icons.calendar_month, label: 'Future Event Calendar', color: Color(0xFFF59E0B)),
                    const _MoreOptionTile(icon: Icons.book, label: 'HW Today in class', color: Color(0xFFEF4444)),
                    const _MoreOptionTile(icon: Icons.mail, label: 'Group Messages', color: Color(0xFF16A34A)),
                    const _MoreOptionTile(icon: Icons.edit, label: 'Write Message', color: Color(0xFF9333EA)),
                    const _MoreOptionTile(icon: Icons.people, label: 'Class Demography', color: Color(0xFF06B6D4)),
                    const _MoreOptionTile(icon: Icons.library_books, label: 'Class Resources', color: Color(0xFF8B5CF6)),
                    const _MoreOptionTile(icon: Icons.photo_camera, label: 'Photos News', color: Color(0xFFEC4899)),
                    const _MoreOptionTile(icon: Icons.schedule, label: 'Class TimeTable', color: Color(0xFF3B82F6)),
                    const _MoreOptionTile(icon: Icons.today, label: 'Class Planner', color: Color(0xFF10B981)),
                    const _MoreOptionTile(icon: Icons.videocam, label: 'Video Conf', color: Color(0xFFDC2626)),
                    const _MoreOptionTile(icon: Icons.description, label: 'Class FilePlan', color: Color(0xFF64748B)),
                    const _MoreOptionTile(icon: Icons.assignment, label: 'Online Assignment', color: Color(0xFFF97316)),
                    const _MoreOptionTile(icon: Icons.assessment, label: 'Online Assessment', color: Color(0xFF6366F1)),
                  ];

                  return items[index];
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _MoreOptionTile extends StatelessWidget {
  const _MoreOptionTile({
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
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
