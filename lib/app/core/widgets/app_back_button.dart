import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../values/app_styles.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
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
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: size * 0.8,
          color: context.textPrimaryColor,
        ),
        onPressed: onPressed ?? () => Get.back(),
      ),
    );
  }
}
