import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import 'student_achievements_awards_page.dart';
import 'student_attendance_page.dart';
import 'student_diary_page.dart';
import 'student_exam_results_page.dart';
import 'student_faculty_feedback_page.dart';
import 'student_fee_information_page.dart';
import 'student_info_screen.dart';
import 'student_medical_page.dart';
import 'student_ptm_page.dart';
import 'student_resources_page.dart';
import 'student_uni_route_page.dart';
import 'student_uniform_request_page.dart';

/// Student menu screen matching the provided reference flow.
class StudentMenuScreen extends StatelessWidget {
  const StudentMenuScreen({
    super.key,
    this.name,
    this.studentId,
    this.admissionNo,
    this.grade,
    this.year,
    this.status,
    this.imageUrl,
  });

  final String? name;
  final String? studentId;
  final String? admissionNo;
  final String? grade;
  final String? year;
  final String? status;
  final String? imageUrl;

  Widget _previewImageWidget(
    String src, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
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
        debugPrint('Failed to decode data URI in StudentMenuScreen: $e');
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
      // On web, local file system paths are not accessible. Try to show as network resource.
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
      debugPrint('Error creating File image in StudentMenuScreen: $e');
      return const Icon(Icons.broken_image);
    }
  }

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              Text(
                name ?? 'Student Name',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 12),
              if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _previewImageWidget(imageUrl!),
                  ),
                ),
              ] else ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Student ID : ${studentId ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Admission No : ${admissionNo ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Grade : ${grade ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Year : ${year ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status : ${status ?? 'Active'}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF222222),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.68,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final items = [
                    _StudentMenuTile(
                      icon: Icons.info,
                      label: 'Student Info',
                      color: const Color(0xFF26C6DA),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentInfoScreen(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.calendar_today,
                      label: 'Attendance\nApply Leave',
                      color: const Color(0xFFF57C00),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentAttendancePage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.bar_chart,
                      label: 'Exam Score',
                      color: const Color(0xFF2E7D32),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentExamResultsPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.menu_book,
                      label: 'Student Diary',
                      color: const Color(0xFF26C6DA),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentDiaryPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.emoji_events,
                      label: 'Achievements\nAwards',
                      color: const Color(0xFF8E24AA),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentAchievementsAwardsPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.payments,
                      label: 'Fee Information',
                      color: const Color(0xFFB0C400),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentFeeInformationPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.checkroom,
                      label: 'Size & Uniform\nOrdering',
                      color: const Color(0xFF2196F3),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentUniformRequestPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.medical_services,
                      label: 'Medical',
                      color: const Color(0xFF90A4AE),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentMedicalPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.folder,
                      label: 'Student Resources',
                      color: const Color(0xFFD84315),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentResourcesPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.feedback,
                      label: 'Feedback',
                      color: const Color(0xFF1E88E5),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentFacultyFeedbackPage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.directions_bus,
                      label: 'Pick Up',
                      color: const Color(0xFF00796B),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentUniRoutePage(),
                        ),
                      ),
                    ),
                    _StudentMenuTile(
                      icon: Icons.assignment_turned_in,
                      label: 'PTM Status',
                      color: const Color(0xFF0D47A1),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StudentPtmPage(),
                        ),
                      ),
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

class _StudentMenuTile extends StatelessWidget {
  const _StudentMenuTile({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
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
            child: Icon(icon, size: 16, color: Colors.white),
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
      ),
    );
  }
}
