import 'package:flutter/gestures.dart';
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
      edgeOffset: 16,
      strokeWidth: 3.0,
      // Use dragDisplacement default; works with Bouncing parent physics.
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

/// Scroll physics that always allow pull-to-refresh (short or long lists)
/// and work inside TabBarView / PageView.
const AppAlwaysScrollPhysics = AlwaysScrollableScrollPhysics(
  parent: BouncingScrollPhysics(),
);

/// ScrollConfiguration that also allows mouse/trackpad drag (emulator/desktop).
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      );
}
