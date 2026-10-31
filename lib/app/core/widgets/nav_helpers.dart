import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';

/// IndexedStack that builds a tab the first time it is shown and then keeps it
/// alive: switching tabs no longer rebuilds the screen (scroll position, loaded
/// lists and text stay), and tabs nobody opens are never built.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget Function()> builders;

  const LazyIndexedStack({super.key, required this.index, required this.builders});

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<Widget?> _tabs = List<Widget?>.filled(widget.builders.length, null);

  @override
  Widget build(BuildContext context) {
    final i = widget.index.clamp(0, widget.builders.length - 1);
    _tabs[i] ??= widget.builders[i]();
    return IndexedStack(
      index: i,
      children: [for (final t in _tabs) t ?? const SizedBox.shrink()],
    );
  }
}

/// Bottom-bar icon of the Messages tab with the unread counter.
class MessagesNavIcon extends StatelessWidget {
  final IconData icon;
  const MessagesNavIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MessagesController>()) return Icon(icon);
    final controller = Get.find<MessagesController>();
    return Obx(() {
      final count = controller.conversations.fold<int>(0, (s, c) => s + c.unreadCount);
      return Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.primary,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(icon),
      );
    });
  }
}
