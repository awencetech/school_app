import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../routes/app_routes.dart';
import '../services/app_state.dart';

class StaffFooter extends StatelessWidget {
  const StaffFooter({super.key, this.currentIndex = 2, this.onItemSelected});

  final int currentIndex;
  final ValueChanged<int>? onItemSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
        BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.user),
        BottomNavigationBarItem(icon: const Icon(Icons.info), label: l10n.help),
        BottomNavigationBarItem(icon: const Icon(Icons.help), label: l10n.support),
        BottomNavigationBarItem(icon: const Icon(Icons.logout), label: l10n.logout),
      ],
    );
  }
}
