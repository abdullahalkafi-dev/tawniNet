import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF71D6C2);
  static const Color secondary = Color(0xFF2C3E50);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE74C3C);
  
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);

  // Dark Theme Tokens (Slate / Charcoal)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF242526);
  static const Color darkInputFill = Color(0xFF2A2B2E);
  static const Color darkBorder = Color(0xFF383838);
  static const Color darkBorderSubtle = Color(0xFF2E2E32);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextHint = Color(0xFF6B7280);
  static const Color darkDivider = Color(0xFF2D2E32);

  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF5AB9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

