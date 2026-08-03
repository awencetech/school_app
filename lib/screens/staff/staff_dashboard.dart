import 'package:flutter/material.dart';

import '../../widgets/role_dashboard.dart';

/// Demo staff dashboard for local testing only.
class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboard(
      title: 'Staff Dashboard',
      username: 'StaffC@22',
      icon: Icons.badge,
    );
  }
}
