import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../routes/app_routes.dart';
// kept minimal: no direct screen imports required for this page
import '../../widgets/admin_bottom_nav.dart';

class AdminOtherOptions extends StatefulWidget {
  const AdminOtherOptions({super.key});

  @override
  State<AdminOtherOptions> createState() => _AdminOtherOptionsState();
}

class _AdminOtherOptionsState extends State<AdminOtherOptions> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.topBar, title: const Text('Other Options')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 600 ? 3 : 4;

            final features = [
              {
                'label': 'main edit',
                'icon': Icons.dashboard_outlined,
              },
              {
                'label': 'Add IDs',
                'icon': Icons.add_circle_outline,
              },
              {
                'label': 'Know Your School',
                'icon': Icons.school_outlined,
              },
              {
                'label': 'Student',
                'icon': Icons.people_outline,
              },
              {
                'label': 'Staff',
                'icon': Icons.badge_outlined,
              },
              {
                'label': 'Staff Resource',
                'icon': Icons.folder_shared_outlined,
              },
            ];

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final item = features[index];
                return InkWell(
                  onTap: () {
                    if (index == 0) {
                      Navigator.of(context).pushNamed(AppRoutes.adminMainEdit);
                    } else if (index == 1) {
                      Navigator.of(context).pushNamed(AppRoutes.adminAdd);
                    } else if (index == 2) {
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminKnowYourSchool,
                      );
                    } else if (index == 3) {
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminStudentOptions,
                      );
                    } else if (index == 4) {
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminStaffOptions,
                      );
                    } else if (index == 5) {
                      Navigator.of(context).pushNamed(
                        AppRoutes.adminOtherStaffResource,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
