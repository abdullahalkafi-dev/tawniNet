import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class HelperMessagesTabView extends GetView<MessagesController> {
  const HelperMessagesTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.isSearching.value) {
            return TextField(
              autofocus: true,
              style: TextStyle(color: context.textPrimaryColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'messages_search'.tr,
                hintStyle: TextStyle(color: context.textHintColor),
                border: InputBorder.none,
              ),
              onChanged: (value) => controller.searchQuery.value = value,
            );
          }
          return Text(
            'helper_messages_tab'.tr,
            style: AppStyles.h1Of(context).copyWith(
              fontSize: 24,
            ),
          );
        }),
        actions: [
          Obx(() {
            if (controller.isSearching.value) {
              return IconButton(
                icon: Icon(Icons.close, color: context.textPrimaryColor),
                onPressed: () {
                  controller.isSearching.value = false;
                  controller.searchQuery.value = '';
                },
              );
            }
            return IconButton(
              icon: Icon(Icons.search, color: context.textPrimaryColor),
              onPressed: () {
                controller.isSearching.value = true;
              },
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: AppPullToRefresh(
        onRefresh: controller.refreshData,
        child: Obx(() {
          if (controller.isLoading.value && controller.filteredChats.isEmpty) {
            return ListView(
              primary: false,
              physics: AppAlwaysScrollPhysics,
              children: const [
                SizedBox(height: 160),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          final list = controller.filteredChats;
          if (list.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: list.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, indent: 80, color: context.borderSubtle),
            itemBuilder: (context, index) {
              return _buildChatItem(context, list[index]);
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          primary: false,
          physics: AppAlwaysScrollPhysics,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: context.textHintColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: AppStyles.h2Of(context).copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Messages from clients will appear here\nwhen they start a conversation',
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium.copyWith(
                      color: context.textHintColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: AppStyles.bodyMedium.copyWith(
                      color: context.textHintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatItem(BuildContext context, ChatSummary chat) {
    return ListTile(
      onTap: () => Get.toNamed(Routes.helperChatDetail, arguments: chat),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.network(
              ApiConstants.resolveImageUrl(chat.image) ?? chat.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 56,
                  height: 56,
                  color: context.inputFillLight,
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/svgs/profile_icon.svg',
                    colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
                  ),
                );
              },
            ),
          ),
          if (chat.isOnline)
            Positioned(
              right: 2,
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
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            chat.time,
            style: AppStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: AppColors.primary,
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
                chat.lastMessage,
                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              const Icon(Icons.done_all, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}
