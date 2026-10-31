import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';

/// Shared confirmation dialogs. Every action that moves money or cannot be
/// undone asks first, with the same look everywhere.
class AppDialogs {
  AppDialogs._();

  /// Returns true when the user confirmed.
  static Future<bool> confirm({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool danger = false,
    Widget? content,
  }) async {
    final result = await Get.dialog<bool>(
      Builder(builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title, style: AppStyles.h2Of(context).copyWith(fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: AppStyles.bodyMediumOf(context)),
              if (content != null) ...[const SizedBox(height: 12), content],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text(cancelLabel ?? 'btn_cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              style: FilledButton.styleFrom(
                backgroundColor: danger ? Colors.red : AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(confirmLabel ?? 'btn_confirm'.tr),
            ),
          ],
        );
      }),
    );
    return result == true;
  }

  /// Asks for a short free-text reason (cancellation, problem report…).
  /// Returns null when dismissed.
  static Future<String?> askReason({
    required String title,
    required String hint,
    String? message,
    int minLength = 3,
    String? confirmLabel,
    bool danger = false,
  }) async {
    final controller = TextEditingController();
    final result = await Get.dialog<String>(
      Builder(builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(builder: (context, setState) {
          final ok = controller.text.trim().length >= minLength;
          return AlertDialog(
            backgroundColor: dark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(title, style: AppStyles.h2Of(context).copyWith(fontSize: 17)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message != null) ...[
                  Text(message, style: AppStyles.bodyMediumOf(context)),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: controller,
                  maxLines: 3,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: hint),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: Text('btn_cancel'.tr)),
              FilledButton(
                onPressed: ok ? () => Get.back(result: controller.text.trim()) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: danger ? Colors.red : AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(confirmLabel ?? 'btn_confirm'.tr),
              ),
            ],
          );
        });
      }),
    );
    controller.dispose();
    return result;
  }
}
