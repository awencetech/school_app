import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentAchievementsAwardsPage extends StatelessWidget {
  const StudentAchievementsAwardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MMHS'),
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Text('No achievements or awards available.'),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
