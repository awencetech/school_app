import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/quick_access_app_bar.dart';

class StudentUniRoutePage extends StatelessWidget {
  const StudentUniRoutePage({
    super.key,
    this.headerTitle = 'MMHS',
    this.quickAccessTitle,
  });

  final String headerTitle;
  final String? quickAccessTitle;

  @override
  Widget build(BuildContext context) {
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
      body: const Center(
        child: Text('Bus route information is currently unavailable.'),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
