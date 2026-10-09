import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';

class StudentMedicalPage extends StatelessWidget {
  const StudentMedicalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MMHS'),
          leading: IconButton(
            onPressed: () => navigateBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              tooltip: 'Medical summary',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentMedicalSummaryPage(),
                ),
              ),
              icon: const Icon(Icons.description_outlined),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Events'),
              Tab(text: 'Tests'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MedicalEmptyState('No medical event records available.'),
            _MedicalEmptyState('No medical records available.'),
          ],
        ),
        bottomNavigationBar: const AppBottomNavigation(),
      ),
    );
  }
}

class StudentMedicalSummaryPage extends StatelessWidget {
  const StudentMedicalSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Summary'),
        leading: IconButton(
          onPressed: () => navigateBack(context),
          icon: const Icon(Icons.close),
        ),
      ),
      body: const _MedicalEmptyState('No medical records available.'),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}

class _MedicalEmptyState extends StatelessWidget {
  const _MedicalEmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
