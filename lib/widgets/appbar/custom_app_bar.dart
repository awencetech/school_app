import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// App-wide dark blue app bar that matches the design.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title = 'SCHOOL NAME',
    this.showBack = false,
  });

  final String title;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.topBar,
      leading: showBack
          ? IconButton(
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.arrow_back_ios_new),
            )
          : null,
      title: Text(
        title,
        style: AppTextStyles.appTitle,
      ),
    );
  }
}

