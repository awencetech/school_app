import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QuickAccessAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const QuickAccessAppBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.topBar,
      centerTitle: true,
      title: Text(title, style: AppTextStyles.appTitle),
      actions: actions,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.white),
        onPressed: () => navigateBack(
          context,
          fallbackRoute: AppRoutes.studentDashboard,
        ),
      ),
    );
  }
}
