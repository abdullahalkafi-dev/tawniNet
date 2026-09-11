import 'package:flutter/material.dart';
import '../values/app_colors.dart';

/// Pull-to-refresh wrapper.
/// Keep this OUTSIDE Obx/GetX rebuilds so the indicator is not recreated mid-gesture.
class AppPullToRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Theme.of(context).cardColor,
      edgeOffset: 28,
      strokeWidth: 3.0,
      onRefresh: () async {
        try {
          await onRefresh();
        } catch (_) {
          // Controllers already surface errors via AppFeedback.
        }
      },
      child: child,
    );
  }
}
