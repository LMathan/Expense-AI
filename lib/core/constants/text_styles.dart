import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Heading typography (using Outfit for a premium fintech feel)
  static TextStyle heading1({required bool isDark}) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle heading2({required bool isDark}) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle heading3({required bool isDark}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  // Body typography (using Inter for maximum readability)
  static TextStyle bodyLarge({required bool isDark}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle bodyMedium({required bool isDark}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  static TextStyle bodySmall({required bool isDark}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  static TextStyle button({required bool isDark}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle caption({required bool isDark}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );
}
