import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../routes/app_routes.dart';

class AddOptions extends StatefulWidget {
  const AddOptions({super.key});

  @override
  State<AddOptions> createState() => _AddOptionsState();
}

class _AddOptionsState extends State<AddOptions> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Add')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            const Text('1. Student Create ID'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminAddStudent);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Student Create ID'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('2. Staff Create ID'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminAddStaff);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Staff Create ID'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('3. Admin Create ID'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminAddAdmin);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Admin Create ID'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('4. Create Group'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminAddGroup);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group_add_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Create Group'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('5. Create Classes'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminAddClasses);
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.class_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Create Classes'),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigationBar(
        currentIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.adminDashboard);
              break;
            case 2:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.adminDashboard,
                (route) => false,
              );
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.supportQuery);
              break;
            case 4:
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
              break;
          }
        },
      ),
    );
  }
}
