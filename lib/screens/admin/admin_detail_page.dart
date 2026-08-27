import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/admin_bottom_nav.dart';

class AdminDetailPage extends StatelessWidget {
  const AdminDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Other Options')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('1. Splash Screen'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminMainEditSplashScreen);
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
                    child: const Icon(Icons.spa, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Splash Screen'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('2. School Settings'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminMainEditSchoolSettings);
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
                    child: const Icon(Icons.school, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('School Settings'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('3. School Content Management'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminMainEditSchoolContent);
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
                    child: const Icon(Icons.library_books, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('School Content Management'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('4. Manage Grade Page'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminMainEditGradePage);
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
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Manage Grade Page'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('5. Content Edit'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.adminMainEditContentEdit);
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
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('Content Edit'),
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
