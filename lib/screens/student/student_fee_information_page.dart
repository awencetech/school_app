import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentFeeInformationPage extends StatelessWidget {
  const StudentFeeInformationPage({super.key});

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
        child: Text('Fee information is currently unavailable.'),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}
