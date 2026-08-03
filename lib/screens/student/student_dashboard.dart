import 'package:flutter/material.dart';

import '../../widgets/role_dashboard.dart';

/// Demo student dashboard for local testing only.
class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboard(
      title: 'Student Dashboard',
      username: 'StudentC@11',
      icon: Icons.school,
    );
  }
}
