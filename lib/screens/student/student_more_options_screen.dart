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
          onPressed: () => Navigator.of(context).maybePop(),
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
                itemCount: 20,
                itemBuilder: (context, index) {
                  final items = [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.groupClassMenu,
                      ),
                      child: const _MoreOptionTile(
                        icon: Icons.menu,
                        label: 'Group/Class Menu',
                        color: Color(0xFF0891B2),
                      ),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.dashboard,
                      label: 'Group Dashboard',
                      color: Color(0xFFF97316),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.checkroom,
                      label: 'Take Attendance',
                      color: Color(0xFF047857),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.upload_file,
                      label: 'Upload HW,CW',
                      color: Color(0xFFDC2626),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.edit,
                      label: 'Write Message',
                      color: Color(0xFF9333EA),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.pie_chart,
                      label: 'Class Demography',
                      color: Color(0xFF22C55E),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.school,
                      label: 'Class Resources',
                      color: Color(0xFF2563EB),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.table_chart,
                      label: 'Class TimeTable',
                      color: Color(0xFFEF4444),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.emoji_events,
                      label: 'Appreciate Award',
                      color: Color(0xFF14B8A6),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.photo,
                      label: 'Photos News',
                      color: Color(0xFF475569),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.online_prediction,
                      label: 'Online Assignment',
                      color: Color(0xFF1D4ED8),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.message,
                      label: 'Write Group Messages',
                      color: Color(0xFF10B981),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.approval,
                      label: 'Leave Approval',
                      color: Color(0xFF9333EA),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.book,
                      label: 'Diary Summary',
                      color: Color(0xFF84CC16),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.folder_open,
                      label: 'Class Resources',
                      color: Color(0xFF2563EB),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.checkroom,
                      label: 'Size & Uniform ordering',
                      color: Color(0xFF1E40AF),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.medical_services,
                      label: 'Medical Details',
                      color: Color(0xFF64748B),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.attach_money,
                      label: 'Fee Information',
                      color: Color(0xFFA3E635),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.person,
                      label: 'Student Resources',
                      color: Color(0xFF2563EB),
                    ),
                    const _MoreOptionTile(
                      icon: Icons.event_available,
                      label: 'PTM Status',
                      color: Color(0xFF1E3A8A),
                    ),
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
