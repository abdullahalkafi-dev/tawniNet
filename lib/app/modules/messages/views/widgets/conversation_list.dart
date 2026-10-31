import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The inbox list shared by the client and helper Messages tabs:
/// skeleton rows on first load, retry on failure, pull to refresh.
class ConversationList extends StatelessWidget {
  final MessagesController controller;
  final String chatRoute;
  final String emptyHint;

  const ConversationList({
    super.key,
    required this.controller,
    required this.chatRoute,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    return AppPullToRefresh(
      onRefresh: controller.refreshData,
      child: Obx(() {
        final list = controller.filteredChats;

        // First load: rows that look like the real ones.
        if (!controller.hasLoadedOnce.value && controller.loadFailed.value == false && list.isEmpty) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: [
              Shimmer(
                child: Column(
                  children: List.generate(
                    7,
                    (_) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: ChatTileSkeleton(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (controller.loadFailed.value && list.isEmpty) {
          return _centered(
            context,
            icon: Icons.cloud_off_outlined,
            title: 'ui_failed_to_load_messages'.tr,
            action: OutlinedButton.icon(
              onPressed: controller.fetchConversations,
              icon: const Icon(Icons.refresh),
              label: Text('booking_retry'.tr),
            ),
          );
        }

        if (list.isEmpty) {
          return _centered(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'ui_no_conversations_yet'.tr,
            subtitle: emptyHint,
          );
        }

        return ListView.separated(
          primary: false,
          physics: AppAlwaysScrollPhysics,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: list.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, indent: 80, color: context.borderSubtle),
          itemBuilder: (context, index) => _tile(context, list[index]),
        );
      }),
    );
  }

  Widget _centered(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        primary: false,
        physics: AppAlwaysScrollPhysics,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: context.textHintColor),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppStyles.h2Of(context).copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 18,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium.copyWith(
                      color: context.textHintColor,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 16), action],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ChatSummary chat) {
    return ListTile(
      onTap: () => Get.toNamed(chatRoute, arguments: chat),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          AppAvatar(url: chat.image, name: chat.name, size: 56),
          if (chat.isOnline)
            PositionedDirectional(
              end: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.cardColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: AppStyles.bodyLargeOf(context).copyWith(
                fontWeight: chat.unreadCount > 0 ? FontWeight.w800 : FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            chat.time,
            style: AppStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: chat.unreadCount > 0 ? AppColors.primary : context.textHintColor,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chat.isBlocked ? 'chat_conversation_blocked'.tr : chat.lastMessage,
                style: AppStyles.bodyMedium.copyWith(
                  color: chat.unreadCount > 0 ? context.textPrimaryColor : context.textHintColor,
                  fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                margin: const EdgeInsetsDirectional.only(start: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
