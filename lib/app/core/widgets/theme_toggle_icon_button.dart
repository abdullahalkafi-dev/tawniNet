import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/theme_service.dart';
import '../values/app_styles.dart';

class ThemeToggleIconButton extends StatelessWidget {
  final double size;

  const ThemeToggleIconButton({
    super.key,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return Obx(() {
      final isDark = themeService.isDarkMode;

      return Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          iconSize: size,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onPressed: themeService.toggleTheme,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey(isDark),
              color: isDark ? Colors.amber : const Color(0xFF0D9488),
              size: size,
            ),
          ),
        ),
      );
    });
  }
}
