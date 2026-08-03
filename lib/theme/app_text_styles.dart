import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized typography for consistent text styling.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get appTitle => GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      );

  static TextStyle get languageTitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryText,
      );

  static TextStyle get pageTitle => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get sectionTitle => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryText,
      );

  static TextStyle get subtitle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryText,
      );

  static TextStyle get body => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.hintText,
      );

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      );
}

