import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  AppStyles._();

  static TextStyle get h1 => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get h2 => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // Dynamic context-aware text styles
  static TextStyle h1Of(BuildContext context) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: context.textPrimaryColor,
      );

  static TextStyle h2Of(BuildContext context) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: context.textPrimaryColor,
      );

  static TextStyle bodyLargeOf(BuildContext context) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: context.textPrimaryColor,
      );

  static TextStyle bodyMediumOf(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: context.textSecondaryColor,
      );
}

extension AppThemeContextExtension on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cardColor =>
      _isDark ? AppColors.darkCard : Colors.white;

  Color get scaffoldBackground =>
      _isDark ? AppColors.darkBackground : AppColors.background;

  Color get surfaceColor =>
      _isDark ? AppColors.darkSurface : Colors.white;

  Color get inputFillColor =>
      _isDark ? AppColors.darkInputFill : const Color(0xFFF9FAFB);

  Color get inputFillLight =>
      _isDark ? AppColors.darkInputFill : const Color(0xFFF3F4F6);

  Color get borderSubtle =>
      _isDark ? AppColors.darkBorderSubtle : const Color(0xFFF3F4F6);

  Color get borderSecondary =>
      _isDark ? AppColors.darkBorder : const Color(0xFFD1D5DB);

  Color get textPrimaryColor =>
      _isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get textSecondaryColor =>
      _isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get textHintColor =>
      _isDark ? AppColors.darkTextHint : AppColors.textHint;

  Color get dividerColor =>
      _isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB);
}
