import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Reusable header row for screen sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.centered = false,
  });

  final String title;
  final Widget? trailing;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    if (centered && trailing == null) {
      return Center(child: Text(title, style: AppTextStyles.sectionTitle));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
        ...[trailing].whereType<Widget>(),
      ],
    );
  }
}
