import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/quick_access_app_bar.dart';

class StudentGroupClassBusPage extends StatelessWidget {
  const StudentGroupClassBusPage({
    super.key,
    this.headerTitle = 'MMHS',
    this.quickAccessTitle,
    this.comingSoon = false,
  });

  final String headerTitle;
  final String? quickAccessTitle;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final message = comingSoon
        ? 'Bus tracking is currently unavailable.'
        : 'Group and bus information is currently unavailable.';

    return Scaffold(
      appBar: quickAccessTitle != null
          ? QuickAccessAppBar(title: quickAccessTitle!)
          : AppBar(
              title: Text(headerTitle),
              leading: IconButton(
                onPressed: () => navigateBack(context),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
      body: Center(child: Text(message)),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
