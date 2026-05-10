import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/messages_controller.dart';

class ChatDetailView extends GetView<MessagesController> {
  const ChatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatSummary chat = Get.arguments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          chat.name,
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Today',
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.blue[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildMessageBubble(
                  'Hi Jenny, good morning 😊',
                  true,
                  chat.image,
                ),
                _buildMessageBubble(
                  'I have booked your house cleaning service for December 23 at 10 AM 😊',
                  true,
                  chat.image,
                ),
                _buildMessageBubble(
                  'Hi, morning too Wilson!',
                  false,
                  chat.image,
                ),
                _buildMessageBubble(
                  'OK, I have received your order. I will come on time at the appointed date.',
                  false,
                  chat.image,
                ),
                _buildMessageBubble(
                  'You\'re welcome, I look forward to welcoming you to my house 😊',
                  true,
                  chat.image,
                ),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isSent, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isSent) ...[
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(imageUrl)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSent
                    ? AppColors.primary.withOpacity(0.5)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isSent ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isSent ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isSent ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isSent) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(imageUrl)),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.image_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
