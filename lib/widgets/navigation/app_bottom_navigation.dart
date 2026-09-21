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
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }
    final homeLabel = l10n?.home ?? 'Home';
    final schoolLabel = l10n?.school ?? 'School';
    final dashboardLabel = l10n?.dashboard ?? 'Dashboard';
    final supportLabel = l10n?.support ?? 'Support';
    final loginLabel = l10n?.login ?? 'Login';
    final logoutLabel = l10n?.logout ?? 'Logout';

    final navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: homeLabel),
      BottomNavigationBarItem(icon: const Icon(Icons.school), label: schoolLabel),
      BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: dashboardLabel),
      BottomNavigationBarItem(
        icon: const Icon(Icons.support_agent),
        label: supportLabel,
      ),
      BottomNavigationBarItem(
        icon: Icon(isLoggedIn ? Icons.logout : Icons.login),
        label: isLoggedIn ? logoutLabel : loginLabel,
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
