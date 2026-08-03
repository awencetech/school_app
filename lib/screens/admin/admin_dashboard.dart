import 'package:flutter/material.dart';

import '../../widgets/role_dashboard.dart';

/// Demo admin dashboard for local testing only.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleDashboard(
      title: 'Admin Dashboard',
      username: 'AdminC@33',
      icon: Icons.admin_panel_settings,
    );
  }
}
