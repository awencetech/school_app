import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentAttendancePage extends StatelessWidget {
  const StudentAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MMHS'),
          leading: IconButton(
            onPressed: () => navigateBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Absence'),
              Tab(text: 'Apply'),
              Tab(text: 'Analytics'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AttendanceEmptyState('No attendance records available.'),
            _AttendanceEmptyState('No leave requests available.'),
            _AttendanceEmptyState('No attendance records available.'),
          ],
        ),
        bottomNavigationBar: const AppBottomNavigation(),
      ),
    );
  }
}

class _AttendanceEmptyState extends StatelessWidget {
  const _AttendanceEmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
