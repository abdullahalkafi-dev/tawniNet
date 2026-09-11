import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared app feedback UI.
/// Errors use soft amber (not harsh red) for less alarm; success uses brand teal.
class AppFeedback {
  AppFeedback._();

  static const Color _errorBg = Color(0xFFFFF7E6);
  static const Color _errorBorder = Color(0xFFF0C36D);
  static const Color _errorText = Color(0xFF8A5A00);
  static const Color _errorIcon = Color(0xFFD97706);

  static const Color _successBg = Color(0xFFE6F7F5);
  static const Color _successBorder = Color(0xFF5EC4B6);
  static const Color _successText = Color(0xFF0F766E);
  static const Color _successIcon = Color(0xFF0D9488);

  static const Color _infoBg = Color(0xFFEFF6FF);
  static const Color _infoBorder = Color(0xFF93C5FD);
  static const Color _infoText = Color(0xFF1E40AF);
  static const Color _infoIcon = Color(0xFF3B82F6);

  static void error(
    String message, {
    String title = 'Something went wrong',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      bg: _errorBg,
      border: _errorBorder,
      text: _errorText,
      icon: Icons.info_outline_rounded,
      iconColor: _errorIcon,
    );
  }

  static void success(
    String message, {
    String title = 'Done',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      bg: _successBg,
      border: _successBorder,
      text: _successText,
      icon: Icons.check_circle_outline_rounded,
      iconColor: _successIcon,
    );
  }

  static void info(
    String message, {
    String title = 'Notice',
    SnackPosition position = SnackPosition.BOTTOM,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      bg: _infoBg,
      border: _infoBorder,
      text: _infoText,
      icon: Icons.info_outline_rounded,
      iconColor: _infoIcon,
    );
  }

  static void _show({
    required String title,
    required String message,
    required SnackPosition position,
    required Color bg,
    required Color border,
    required Color text,
    required IconData icon,
    required Color iconColor,
  }) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: position,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        backgroundColor: bg,
        colorText: text,
        borderColor: border,
        borderWidth: 1,
        icon: Icon(icon, color: iconColor, size: 22),
        shouldIconPulse: false,
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutCubic,
      );
    } catch (_) {
      // Fallback if Get context is not ready
    }
  }
}
