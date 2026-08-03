import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Large rounded button (yellow by default) used for primary actions.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.yellowButton,
    this.textColor = AppColors.primaryText,
    this.height = 54,
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonText.copyWith(color: textColor),
        ),
      ),
    );
  }
}

