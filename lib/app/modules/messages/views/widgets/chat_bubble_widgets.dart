import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/chat_detail_controller.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_card_widget.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Shared message bubble widgets used by both client and helper chat views.

Widget buildDateSeparator(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(date.year, date.month, date.day);

  String label;
  if (messageDate == today) {
    label = 'chat_today'.tr;
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    label = 'Yesterday';
  } else {
    label = '${date.day}/${date.month}/${date.year}';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.blue[300],
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

Widget buildMessageWidget(
  ChatMessage message,
  bool isSent,
  String otherAvatar,
  ChatDetailController controller,
  BuildContext context,
) {
  switch (message.type) {
    case 'image':
      return buildImageMessage(message, isSent, otherAvatar);
    case 'video':
      return buildVideoMessage(message, isSent, otherAvatar, context);
    case 'offer':
      return buildOfferMessage(message, isSent, otherAvatar, controller, context);
    default:
      return buildTextMessage(message, isSent, otherAvatar);
  }
}

Widget buildTextMessage(ChatMessage message, bool isSent, String otherAvatar) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: otherAvatar.isNotEmpty ? NetworkImage(otherAvatar) : null,
            child: otherAvatar.isEmpty ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSent
                  ? AppColors.primary.withOpacity(0.8)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isSent ? const Radius.circular(16) : Radius.zero,
                bottomRight: isSent ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content ?? '',
                  style: TextStyle(
                    color: isSent ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isSent ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildImageMessage(ChatMessage message, bool isSent, String otherAvatar) {
  final images = message.images;
  if (images.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: otherAvatar.isNotEmpty ? NetworkImage(otherAvatar) : null,
            child: otherAvatar.isEmpty ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSent
                  ? AppColors.primary.withOpacity(0.8)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildImageGrid(images),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isSent ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildVideoMessage(
  ChatMessage message,
  bool isSent,
  String otherAvatar,
  BuildContext context,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: otherAvatar.isNotEmpty ? NetworkImage(otherAvatar) : null,
            child: otherAvatar.isEmpty ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSent
                  ? AppColors.primary.withOpacity(0.8)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    if (message.video != null && message.video!.isNotEmpty) {
                      // TODO: Open video player
                    }
                  },
                  child: Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isSent ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildOfferMessage(
  ChatMessage message,
  bool isSent,
  String otherAvatar,
  ChatDetailController controller,
  BuildContext context,
) {
  final currentUserId = Get.find<AuthService>().currentUser.value?.id;
  final isHelper = message.senderId == currentUserId;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: otherAvatar.isNotEmpty ? NetworkImage(otherAvatar) : null,
            child: otherAvatar.isEmpty ? const Icon(Icons.person, size: 16) : null,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: OfferCardWidget(
            message: message,
            isSentByMe: isSent,
            isHelper: isHelper,
            onAccept: () => controller.acceptOffer(message.id),
            onReject: () => controller.rejectOffer(message.id),
            onCancel: () => controller.cancelOffer(message.id),
            onEdit: () {
              if (message.offerData == null) return;
              // Show edit offer bottom sheet
            },
          ),
        ),
      ],
    ),
  );
}

Widget _buildImageGrid(List<String> images) {
  final count = images.length.clamp(1, 4);

  if (count == 1) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        images[0],
        width: 200,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }

  return SizedBox(
    width: 200,
    height: 150,
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count > 2 ? 2 : count,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 20),
            ),
          ),
        );
      },
    ),
  );
}

String _formatTime(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
}
