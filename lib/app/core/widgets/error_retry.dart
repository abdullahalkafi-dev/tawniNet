import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';

/// "Could not load" state with a retry button. Used where a screen would
/// otherwise stay empty (or show made-up data) after a network failure.
class ErrorRetry extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final double minHeight;

  const ErrorRetry({
    super.key,
    required this.onRetry,
    this.message,
    this.minHeight = 320,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 56, color: context.textHintColor),
              const SizedBox(height: 12),
              Text(
                message ?? 'error_load_failed'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('booking_retry'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
