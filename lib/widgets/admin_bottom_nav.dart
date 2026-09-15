import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../generated/l10n/app_localizations.dart';
import '../routes/app_routes.dart';
import '../services/app_state.dart';
import '../services/user_menu_state.dart';

/// Shared footer navigation for the admin dashboard section only.
/// Manages the User button popup menu with proper toggle behavior.
class AdminBottomNavigationBar extends StatelessWidget {
  const AdminBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

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
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 9,
        fontWeight: FontWeight.w400,
      ),
      elevation: 0,
      iconSize: 22,
      currentIndex: currentIndex,
      onTap: (index) async {
        // User button: toggle menu instead of navigating
        if (index == 1) {
          context.read<UserMenuState>().toggle();
          return;
        }

        // Logout button
        if (index == 4) {
          context.read<UserMenuState>().close();
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          );
          return;
        }

        // Other buttons
        context.read<UserMenuState>().close();
        onItemSelected(index);
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
