import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../services/app_state.dart';

class StaffFooter extends StatelessWidget {
  const StaffFooter({super.key, this.currentIndex = 2, this.onItemSelected});

  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF333856),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withValues(alpha: 0.8),
      selectedFontSize: 9,
      unselectedFontSize: 9,
      elevation: 0,
      currentIndex: currentIndex,
      onTap: (index) async {
        if (onItemSelected != null) {
          onItemSelected!(index);
          return;
        }
        if (index == 4) {
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Help'),
        BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Support'),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Quick Menu'),
      ],
    );
  }
}
