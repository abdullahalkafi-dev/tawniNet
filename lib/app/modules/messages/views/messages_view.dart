import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/messages_controller.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Messages',
          style: AppStyles.h1.copyWith(
            fontSize: 24,
            color: const Color(0xFF1F2A37),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: controller.chats.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 80),
          itemBuilder: (context, index) {
            return _buildChatItem(controller.chats[index]);
          },
        );
      }),
    );
  }

  Widget _buildChatItem(ChatSummary chat) {
    return ListTile(
      onTap: () => Get.toNamed('/chat-detail', arguments: chat),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(radius: 28, backgroundImage: NetworkImage(chat.image)),
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
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            chat.name,
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
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
                style: AppStyles.bodyMedium.copyWith(color: Colors.grey[500]),
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
