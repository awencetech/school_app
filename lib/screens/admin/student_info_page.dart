import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/school_config_service.dart';
import '../../services/student_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/staff_footer.dart';

class StudentInfoPage extends StatefulWidget {
  const StudentInfoPage({super.key, this.student});

  final StudentRecord? student;

  @override
  State<StudentInfoPage> createState() => _StudentInfoPageState();
}

class _StudentInfoPageState extends State<StudentInfoPage> {
  StudentRecord? _student;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _photoFor(String? imageUrl, String name) {
    final src = imageUrl?.trim() ?? '';
    if (src.isEmpty) {
      return Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF3E5BA9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _initials(name),
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (src.startsWith('data:')) {
      try {
        final comma = src.indexOf(',');
        final bytes = base64Decode(src.substring(comma + 1));
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackAvatar(name),
          ),
        );
      } catch (_) {
        return _fallbackAvatar(name);
      }
    }

    if (src.startsWith('http://') || src.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          src,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackAvatar(name),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        src,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackAvatar(name),
      ),
    );
  }

  Widget _fallbackAvatar(String name) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF3E5BA9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final config = context.watch<SchoolConfigService>();
    final name = student?.name ?? 'Student';
    final className = student?.className ?? 'N/A';
    final section = student?.section.isNotEmpty == true ? student!.section : 'N/A';
    final studentId = student?.studentId ?? 'N/A';
    final admissionNo = student?.admissionNumber ?? 'N/A';
    final mobile = student?.mobileNumber ?? 'N/A';
    final address = student?.address ?? 'N/A';
    final about = student?.about ?? 'N/A';
    final hobbies = student?.hobbies ?? 'N/A';
    final parentName = student?.parentName ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.topBar,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: const Text('Student Info', style: TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Student Info'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _StudentDetails(
                          name: name,
                          className: className,
                          section: section,
                          studentId: studentId,
                          admissionNo: admissionNo,
                          parentName: parentName,
                          mobile: mobile,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _photoFor(student?.imageUrl ?? config.secretaryPhotoBase64, name),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(title: 'Classes and Groups of $name'),
                  const SizedBox(height: 4),
                  const _ClassesTable(),
                  const SizedBox(height: 28),
                  _OtherDetails(
                    student: student,
                    address: address,
                    about: about,
                    hobbies: hobbies,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const StaffFooter(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F2937),
      ),
    );
  }
}

class _StudentDetails extends StatelessWidget {
  const _StudentDetails({
    required this.name,
    required this.className,
    required this.section,
    required this.studentId,
    required this.admissionNo,
    required this.parentName,
    required this.mobile,
  });

  final String name;
  final String className;
  final String section;
  final String studentId;
  final String admissionNo;
  final String parentName;
  final String mobile;

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRowData>[
      _InfoRowData('Student Name', name),
      _InfoRowData('Class', className),
      _InfoRowData('Section', section),
      _InfoRowData('Student ID', studentId),
      _InfoRowData('Admission No', admissionNo),
      _InfoRowData('Parent Name', parentName),
      _InfoRowData('Mobile No', mobile),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) => _InfoRow(row.label, row.value)).toList(),
    );
  }
}

class _InfoRowData {
  const _InfoRowData(this.label, this.value);

  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1F2937)),
          children: [
            TextSpan(text: '$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ClassesTable extends StatelessWidget {
  const _ClassesTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF9CA3AF), width: 1.2),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _TableCell('Group/Class', isHeader: true),
              ),
              Expanded(
                child: _TableCell('Year', isHeader: true),
              ),
              Expanded(
                child: _TableCell('Type', isHeader: true),
              ),
              Expanded(
                child: _TableCell('Status', isHeader: true),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(child: _TableCell('Not associated with any class or group')),
              Expanded(child: _TableCell('-')),
              Expanded(child: _TableCell('-')),
              Expanded(child: _TableCell('N/A')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell(this.text, {this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9CA3AF), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _OtherDetails extends StatelessWidget {
  const _OtherDetails({
    required this.student,
    required this.address,
    required this.about,
    required this.hobbies,
  });

  final StudentRecord? student;
  final String address;
  final String about;
  final String hobbies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Other Details',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 10),
        _DetailSection(label: 'Student ID', value: student?.studentId ?? 'N/A'),
        _DetailSection(label: 'Admission No', value: student?.admissionNumber ?? 'N/A'),
        _DetailSection(label: 'Address', value: address),
        _DetailSection(label: 'About', value: about),
        _DetailSection(label: 'Hobbies', value: hobbies),
        _DetailSection(label: 'Parent Name', value: student?.parentName ?? 'N/A'),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}
