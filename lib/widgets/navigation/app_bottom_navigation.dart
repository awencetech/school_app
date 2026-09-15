import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/app_state.dart';
import '../../theme/app_colors.dart';

/// Bottom navigation used on the main area screens.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    AppState? state;
    try {
      state = context.watch<AppState>();
    } catch (_) {
      state = null;
    }

    final isLoggedIn = state?.isLoggedIn ?? false;
    final l10n = AppLocalizations.of(context);
    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
      BottomNavigationBarItem(icon: const Icon(Icons.school), label: l10n.school),
      BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: l10n.dashboard),
      BottomNavigationBarItem(
        icon: Icon(Icons.support_agent),
        label: l10n.support,
      ),
      BottomNavigationBarItem(
        icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
        label: isLoggedIn ? l10n.logout : l10n.login,
      ),
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF333856),
      selectedItemColor: AppColors.white,
      unselectedItemColor: AppColors.white.withValues(alpha: 0.82),
      selectedFontSize: 10,
      unselectedFontSize: 10,
      currentIndex: state?.bottomNavIndex ?? 0,
      onTap: (index) async {
        if (index == 4 && isLoggedIn) {
          await state?.logout();
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
          return;
        }

        state?.setBottomNavIndex(index);

        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute == AppRoutes.createAccount ||
            currentRoute == AppRoutes.forgotPassword) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          );
        }
      },
      items: navItems,
    );
  }
}
