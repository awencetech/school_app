import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Text field with consistent styling and rounded borders.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isPasswordVisible;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = !widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final showVisibilityToggle = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.subtitle),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: showVisibilityToggle && !_isPasswordVisible,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          style: AppTextStyles.body.copyWith(color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.hintText),
            filled: true,
            fillColor: AppColors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.blueButton),
            ),
            suffixIcon: showVisibilityToggle
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.hintText,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

