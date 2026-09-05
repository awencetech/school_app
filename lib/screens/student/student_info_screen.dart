import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/app_state.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import 'student_full_details_page.dart';

/// Student information screen matching the provided school ERP reference design.
class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  StudentRecord? _student;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    try {
      final appState = context.read<AppState>();
      await appState.initialization;
      final token = appState.currentAuthToken?.trim() ?? '';
      if (token.isEmpty) return;
      final student = await StudentService().getCurrentProfile(token: token);
      if (mounted) setState(() => _student = student);
    } catch (_) {
      // Keep the screen available when opened outside an authenticated route.
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final studentName = student?.name.trim().isNotEmpty == true
        ? student!.name
        : 'Student name';
    final studentId = student?.studentId.trim().isNotEmpty == true
        ? student!.studentId
        : student?.admissionNumber ?? '';
    final mobileNumber = student?.mobileNumber ?? '';
    final address = student?.address.trim().isNotEmpty == true
        ? student!.address
        : 'Address not available';
    final className = [student?.className ?? '', student?.section ?? '']
        .where((value) => value.trim().isNotEmpty)
        .join(' - ');

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
                'Student Info',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoValue(label: 'Student name', value: studentName),
                        _InfoValue(label: 'Student ID', value: studentId),
                        _InfoValue(
                          label: 'Mail ID :',
                          value: '',
                        ),
                        _InfoValue(label: 'Mobile No :', value: mobileNumber),
                        const _InfoValue(label: 'Special Needs :', value: ''),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 120,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                            image: student?.imageUrl.trim().isNotEmpty == true
                                ? DecorationImage(
                                    image: NetworkImage(student!.imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 32, color: Colors.white),
                            const SizedBox(height: 6),
                            Text(
                              'Take photo',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StudentFullDetailsPage()),
                    ),
                    child: const _CompactActionItem(
                      icon: Icons.info,
                      label: 'View More',
                      backgroundColor: Color(0xFF1976D2),
                    ),
                  ),
                  const _CompactActionItem(
                    icon: Icons.edit,
                    label: 'Edit Details',
                    backgroundColor: Color(0xFFD84315),
                  ),
                  const _CompactActionItem(
                    icon: Icons.accessibility_new,
                    label: 'Special Needs',
                    backgroundColor: Color(0xFF8D6E63),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Address',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Groups and Classes of $studentName',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF9CA3AF), width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                                bottom: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              'Type',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                                bottom: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              'Year',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              'Group/Class',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              'Transport',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              className.isEmpty ? 'Not available' : className,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            child: Text(
                              'Parent Pickup or School Bus',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                                top: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              'Main',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                right: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                                top: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              '20XX - 20XX',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Color(0xFF9CA3AF), width: 1.2),
                              ),
                            ),
                            child: Text(
                              className.isEmpty ? 'Not available' : className,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Your Location',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFDCE8F7),
                  border: Border.all(color: const Color(0xFFB8D0EA)),
                ),
                child: const Center(
                  child: Text(
                    'Map View',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Last updated',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
              ),
              const SizedBox(height: 18),
              Text(
                'Parent Details',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              _ParentDetailsCard(
                title: 'Parent Photo',
                nameLabel: 'Contact Name :',
                relationshipLabel: 'Relationship :',
                mobileLabel: 'Mobile Number :',
                emailLabel: 'Email ID :',
              ),
              const SizedBox(height: 12),
              _ParentDetailsCard(
                title: 'Parent Photo',
                nameLabel: 'Contact Name :',
                relationshipLabel: 'Relationship :',
                mobileLabel: 'Mobile Number :',
                emailLabel: 'Email ID :',
              ),
              const SizedBox(height: 12),
              _ParentDetailsCard(
                title: 'Family Photo',
                nameLabel: 'Contact Name :',
                relationshipLabel: 'Relationship :',
                mobileLabel: 'Mobile Number :',
                emailLabel: 'Email ID :',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  const _InfoLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _InfoValue extends StatelessWidget {
  const _InfoValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactActionItem extends StatelessWidget {
  const _CompactActionItem({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: backgroundColor,
          child: Icon(
            icon,
            size: 18,
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
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class _ParentDetailsCard extends StatelessWidget {
  const _ParentDetailsCard({
    required this.title,
    required this.nameLabel,
    required this.relationshipLabel,
    required this.mobileLabel,
    required this.emailLabel,
  });

  final String title;
  final String nameLabel;
  final String relationshipLabel;
  final String mobileLabel;
  final String emailLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLabel(nameLabel),
                _InfoLabel(relationshipLabel),
                _InfoLabel(mobileLabel),
                _InfoLabel(emailLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
