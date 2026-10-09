import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../services/student_service.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import 'student_full_details_page.dart';

class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  StudentRecord? _student;
  bool _loading = true;

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
    } catch (error) {
      debugPrint('Unable to load the authenticated student profile: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final fields = student == null
        ? const <({String label, String value})>[]
        : <({String label, String value})>[
            (label: 'Student name', value: student.name),
            (label: 'Student ID', value: student.studentId),
            (label: 'Admission number', value: student.admissionNumber),
            (
              label: 'Class',
              value: [student.className, student.section]
                  .where((part) => part.trim().isNotEmpty)
                  .join(' - '),
            ),
            (label: 'Parent name', value: student.parentName),
            (label: 'Mobile number', value: student.mobileNumber),
            (label: 'Address', value: student.address),
            (label: 'About', value: student.about),
            (label: 'Hobbies', value: student.hobbies),
          ].where((field) => field.value.trim().isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MMHS'),
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : student == null
          ? const Center(
              child: Text('Student information is currently unavailable.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (student.imageUrl.trim().isNotEmpty)
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: NetworkImage(student.imageUrl),
                      onBackgroundImageError: (_, _) {},
                    ),
                  )
                else
                  const Center(
                    child: CircleAvatar(
                      radius: 44,
                      child: Icon(Icons.person, size: 44),
                    ),
                  ),
                const SizedBox(height: 16),
                for (final field in fields)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(field.label),
                    subtitle: Text(field.value),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            StudentFullDetailsPage(student: student),
                      ),
                    ),
                    child: const Text('View details'),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
