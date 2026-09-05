import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';

/// Admin view of student menu displaying student details and quick action options.
class AdminStudentMenuPage extends StatelessWidget {
  const AdminStudentMenuPage({
    super.key,
    required this.student,
  });

  final StudentRecord student;

  Widget _previewImageWidget(
    String src, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (src.isEmpty) {
      return const Icon(Icons.image_not_supported);
    }

    if (src.startsWith('data:')) {
      try {
        final comma = src.indexOf(',');
        final b64 = src.substring(comma + 1);
        final bytes = base64Decode(b64);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
        );
      } catch (e) {
        debugPrint('Failed to decode data URI: $e');
        return const Icon(Icons.broken_image);
      }
    }

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
      );
    }

    if (kIsWeb) {
      return Image.network(
        src,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
      );
    }

    try {
      return Image.file(
        File(src),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      );
    } catch (e) {
      debugPrint('Error creating File image: $e');
      return const Icon(Icons.broken_image);
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            navigateBack(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: Text(
          'Student Menu',
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Menu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),
              // Student Name
              Text(
                student.name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 12),
              // Student Image
              if (student.imageUrl.isNotEmpty)
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _previewImageWidget(student.imageUrl),
                  ),
                )
              else
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(student.name),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // Student Details
              Text(
                'Student ID : ${student.studentId}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Admission No : ${student.admissionNumber}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Grade : ${student.className}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Year : 2024',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status : Active',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 24),
              // Menu Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: const [
                  _StudentMenuTile(
                    icon: Icons.info,
                    label: 'Student Info',
                    color: Color(0xFF26C6DA),
                  ),
                  _StudentMenuTile(
                    icon: Icons.calendar_today,
                    label: 'Attendance\nApply Leave',
                    color: Color(0xFFF57C00),
                  ),
                  _StudentMenuTile(
                    icon: Icons.bar_chart,
                    label: 'Exam Score',
                    color: Color(0xFF2E7D32),
                  ),
                  _StudentMenuTile(
                    icon: Icons.menu_book,
                    label: 'Student Diary',
                    color: Color(0xFF26C6DA),
                  ),
                  _StudentMenuTile(
                    icon: Icons.emoji_events,
                    label: 'Achievements\nAwards',
                    color: Color(0xFF8E24AA),
                  ),
                  _StudentMenuTile(
                    icon: Icons.payments,
                    label: 'Fee Information',
                    color: Color(0xFFB0C400),
                  ),
                  _StudentMenuTile(
                    icon: Icons.checkroom,
                    label: 'Size & Uniform\nOrdering',
                    color: Color(0xFF2196F3),
                  ),
                  _StudentMenuTile(
                    icon: Icons.medical_services,
                    label: 'Medical',
                    color: Color(0xFF90A4AE),
                  ),
                  _StudentMenuTile(
                    icon: Icons.folder,
                    label: 'Student Resources',
                    color: Color(0xFFD84315),
                  ),
                  _StudentMenuTile(
                    icon: Icons.assignment_turned_in,
                    label: 'PTM Status',
                    color: Color(0xFF0D47A1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 3,
        onItemSelected: (_) {},
      ),
    );
  }
}

class _StudentMenuTile extends StatelessWidget {
  const _StudentMenuTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(height: 3),
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
      ),
    );
  }
}
