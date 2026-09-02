import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../routes/app_routes.dart';

/// A popup menu that appears above the User button in the bottom navigation.
/// This widget positions itself above the bottom nav without covering the button.
class UserActionMenu extends StatelessWidget {
  const UserActionMenu({
    super.key,
    required this.onProfileTap,
    required this.onPasswordTap,
  });

  final VoidCallback onProfileTap;
  final VoidCallback onPasswordTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 65, // Above the bottom navigation bar
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: const Color(0xFFD4D4D4)),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _MenuItem(
                  icon: Icons.person,
                  label: 'Update User\nProfile',
                  iconColor: const Color(0xFFD9007F),
                  onTap: onProfileTap,
                ),
              ),
              Expanded(
                child: _MenuItem(
                  icon: Icons.lock,
                  label: 'Change\nPassword',
                  iconColor: const Color(0xFFC99700),
                  onTap: onPasswordTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: iconColor,
              child: Icon(icon, size: 13, color: AppColors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                height: 1.05,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
