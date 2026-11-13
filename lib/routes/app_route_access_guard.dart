import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'app_routes.dart';

class AppRouteAccessGuard extends StatefulWidget {
  const AppRouteAccessGuard({
    required this.child,
    required this.allowedRoles,
    super.key,
  });

  final Widget child;
  final Set<String>? allowedRoles;

  @override
  State<AppRouteAccessGuard> createState() => _AppRouteAccessGuardState();
}

class _AppRouteAccessGuardState extends State<AppRouteAccessGuard> {
  bool _redirectScheduled = false;

  @override
  Widget build(BuildContext context) {
    final allowedRoles = widget.allowedRoles;
    if (allowedRoles == null) return widget.child;

    final appState = context.watch<AppState>();
    if (!appState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = AppState.normalizeSupportedRole(appState.currentUserRole);
    if (!appState.isLoggedIn || role == null) {
      _scheduleLoginRedirect(appState);
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!allowedRoles.contains(role)) {
      final dashboard = AppRoutes.dashboardForRole(role);
      if (dashboard != null) {
        _scheduleRouteReplacement(dashboard);
      } else {
        _scheduleLoginRedirect(appState);
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.child;
  }

  void _scheduleLoginRedirect(AppState appState) {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await appState.logout();
      if (!mounted) return;
      appState.setBottomNavIndex(4);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    });
  }

  void _scheduleRouteReplacement(String route) {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
    });
  }
}
