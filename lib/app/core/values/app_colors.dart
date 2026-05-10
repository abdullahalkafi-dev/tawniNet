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

  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF5AB9A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
