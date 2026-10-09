import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../services/student_service.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentFullDetailsPage extends StatelessWidget {
  const StudentFullDetailsPage({super.key, this.student});

  final StudentRecord? student;

  @override
  Widget build(BuildContext context) {
    final record = student;
    final fields = record == null
        ? const <({String label, String value})>[]
        : <({String label, String value})>[
            (label: 'Student name', value: record.name),
            (label: 'Student ID', value: record.studentId),
            (label: 'Admission number', value: record.admissionNumber),
            (label: 'Class', value: record.className),
            (label: 'Section', value: record.section),
            (label: 'Parent name', value: record.parentName),
            (label: 'Mobile number', value: record.mobileNumber),
            (label: 'Address', value: record.address),
            (label: 'About', value: record.about),
            (label: 'Hobbies', value: record.hobbies),
            (label: 'Role', value: record.role),
          ].where((field) => field.value.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: record == null || fields.isEmpty
          ? const Center(
              child: Text('Student details are currently unavailable.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final field in fields)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(field.label),
                    subtitle: Text(field.value),
                  ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
