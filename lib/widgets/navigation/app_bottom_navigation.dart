import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/app_routes.dart';
import '../../services/app_state.dart';

/// Bottom navigation used on the main area screens.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        return BottomNavigationBar(
          currentIndex: state.bottomNavIndex,
          onTap: (index) {
            state.setBottomNavIndex(index);

            final currentRoute = ModalRoute.of(context)?.settings.name;
            if (currentRoute == AppRoutes.createAccount ||
                currentRoute == AppRoutes.forgotPassword) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.main,
                (route) => false,
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.school), label: 'School'),
            BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events), label: 'Exploit'),
            BottomNavigationBarItem(
                icon: Icon(Icons.support_agent), label: 'Support'),
            BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
          ],
        );
      },
    );
  }
}
