import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/navigation/app_bottom_navigation.dart';
import '../../widgets/quick_access_app_bar.dart';

class StudentUniRoutePage extends StatelessWidget {
  const StudentUniRoutePage({
    super.key,
    this.routeName = 'UNI-Route-Z2',
    this.headerTitle = 'SAMUNI',
    this.quickAccessTitle,
    this.showComingSoon = true,
  });

  final String routeName;
  final String headerTitle;
  final String? quickAccessTitle;
  final bool showComingSoon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: quickAccessTitle != null
          ? QuickAccessAppBar(title: quickAccessTitle!)
          : AppBar(
              backgroundColor: const Color(0xff34395f),
              elevation: 0,
              toolbarHeight: 44,
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () => navigateBack(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              centerTitle: true,
              title: Text(
                headerTitle,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
      body: const Center(
        child: Text('Coming soon...!!'),
      ),
      bottomNavigationBar: const AppBottomNavigation(),
    );
  }
}