import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
        title: Obx(() {
          if (controller.isSearching.value) {
            return TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
              onChanged: (value) => controller.searchQuery.value = value,
            );
          }
          return Text(
            'Messages',
            style: AppStyles.h1.copyWith(
              fontSize: 24,
              color: const Color(0xFF1F2A37),
            ),
          );
        }),
        actions: [
          Obx(() {
            if (controller.isSearching.value) {
              return IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  controller.isSearching.value = false;
                  controller.searchQuery.value = '';
                },
              );
            }
            return IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                controller.isSearching.value = true;
              },
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final list = controller.filteredChats;
        if (list.isEmpty) {
          return const Center(child: Text('No messages found'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: list.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, indent: 80),
          itemBuilder: (context, index) {
            return _buildChatItem(list[index]);
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
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.network(
              chat.image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/svgs/profile_icon.svg',
                    colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
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
