import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UploadProgressDialog extends StatelessWidget {
  final RxDouble progress;
  final RxString status;

  const UploadProgressDialog({
    super.key,
    required this.progress,
    required this.status,
  });

  /// Show the dialog and return it. Caller should dismiss with Get.back().
  static UploadProgressDialog show({RxDouble? progress, RxString? status}) {
    final p = progress ?? 0.0.obs;
    final s = status ?? 'Preparing...'.obs;

    Get.dialog(
      UploadProgressDialog(progress: p, status: s),
      barrierDismissible: false,
    );

    return UploadProgressDialog(progress: p, status: s);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progress.value > 0 ? progress.value : null,
                    strokeWidth: 4,
                    color: AppColors.primary,
                  ),
                )),
            const SizedBox(height: 16),
            Obx(() => Text(
                  status.value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                )),
            const SizedBox(height: 8),
            Obx(() => progress.value > 0
                ? Text(
                    '${(progress.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
