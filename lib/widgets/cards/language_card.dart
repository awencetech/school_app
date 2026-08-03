import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Language selection card with circular icon and arrow indicator.
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final Color iconColor;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.tamilIcon : Colors.transparent,
              width: selected ? 2 : 0,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor,
                ),
                child: Center(
                  child: Icon(
                    Icons.language,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.subtitle,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.hintText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

