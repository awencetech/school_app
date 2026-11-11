import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes/app_routes.dart';
import '../services/app_state.dart';

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  final Future<void> Function() onConfirm;

  static Future<bool> show(
    BuildContext context, {
    required Future<void> Function() onConfirm,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout confirmation',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return LogoutConfirmationDialog(onConfirm: onConfirm);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  State<LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog> {
  bool _isProcessing = false;

  Future<void> _confirmLogout() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final red = theme.colorScheme.error;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.white,
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.logout_rounded, color: red, size: 32),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Confirm Logout',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Are you sure you want to log out of your account?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: const Color(0xFF5F6368),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isProcessing
                            ? null
                            : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3C4043),
                          backgroundColor: const Color(0xFFF5F6F7),
                          side: const BorderSide(color: Color(0xFFE1E4E8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('No, Stay Logged In'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isProcessing ? null : _confirmLogout,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.logout_rounded, size: 18),
                        label: Text(
                          _isProcessing ? 'Logging out...' : 'Yes, Logout',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> confirmAndLogout(BuildContext context) async {
  // Capture the provider-backed state before opening the dialog. The dialog is
  // presented on a new route, so the original app state is the authoritative
  // session owner for both the logout and the post-logout navigation state.
  final appState = context.read<AppState>();
  final confirmed = await LogoutConfirmationDialog.show(
    context,
    onConfirm: appState.logout,
  );
  if (!confirmed || !context.mounted) return;
  // AppState.logout() resets the navigation index to the public Home tab as
  // part of its existing cleanup. Select the existing Login tab explicitly so
  // the user is not left looking at the public home screen after logout.
  appState.setBottomNavIndex(4);
  Navigator.of(context).pushNamedAndRemoveUntil(
    AppRoutes.main,
    (route) => false,
  );
}
