import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/media_downloader.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_card_widget.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/video_player_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/video_thumbnail.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget buildDateSeparator(BuildContext context, DateTime date) {
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
          color: context.isDarkMode
              ? AppColors.primary.withOpacity(0.2)
              : Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            color: context.isDarkMode ? AppColors.primary : Colors.blue[300],
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

Widget buildMessageWidget(
  BuildContext context,
  ChatMessage message,
  bool isSent, {
  required String chatAvatar,
  required VoidCallback? onAcceptOffer,
  required VoidCallback? onRejectOffer,
  required VoidCallback? onCancelOffer,
  required VoidCallback? onEditOffer,
}) {
  // Prefer the resolved sender avatar from the message payload.
  final avatar = ApiConstants.resolveImageUrl(
            message.senderAvatar.isNotEmpty ? message.senderAvatar : chatAvatar,
          ) ??
      '';
  switch (message.type) {
    case 'image':
      return buildImageMessage(context, message, isSent, chatAvatar: avatar);
    case 'video':
      return buildVideoMessage(context, message, isSent, chatAvatar: avatar);
    case 'offer':
      return buildOfferMessage(
        message,
        isSent,
        chatAvatar: avatar,
        onAccept: onAcceptOffer,
        onReject: onRejectOffer,
        onCancel: onCancelOffer,
        onEdit: onEditOffer,
      );
    default:
      return buildTextMessage(context, message, isSent, chatAvatar: avatar);
  }
}

Widget _peerAvatar(String chatAvatar) {
  return CircleAvatar(
    radius: 16,
    backgroundColor: AppColors.primary.withOpacity(0.25),
    backgroundImage:
        chatAvatar.isNotEmpty ? NetworkImage(chatAvatar) : null,
    onBackgroundImageError: (_, __) {},
    child: chatAvatar.isEmpty
        ? const Icon(Icons.person, size: 16, color: AppColors.primary)
        : null,
  );
}

Widget buildTextMessage(
  BuildContext context,
  ChatMessage message,
  bool isSent, {
  required String chatAvatar,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment:
          isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          _peerAvatar(chatAvatar),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSent
                  ? AppColors.primary.withOpacity(0.85)
                  : context.cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isSent ? const Radius.circular(16) : Radius.zero,
                bottomRight: isSent ? Radius.zero : const Radius.circular(16),
              ),
              border: isSent ? null : Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.content ?? '',
                  style: TextStyle(
                    color: isSent ? Colors.white : context.textPrimaryColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isSent ? Colors.white70 : context.textHintColor,
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

Widget buildImageMessage(
  BuildContext context,
  ChatMessage message,
  bool isSent, {
  required String chatAvatar,
}) {
  final images = message.images;
  if (images.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment:
          isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          _peerAvatar(chatAvatar),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSent
                  ? AppColors.primary.withOpacity(0.85)
                  : context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isSent ? null : Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildImageGrid(context, images),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isSent ? Colors.white70 : context.textHintColor,
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
  BuildContext context,
  ChatMessage message,
  bool isSent, {
  required String chatAvatar,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment:
          isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          _peerAvatar(chatAvatar),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSent
                  ? AppColors.primary.withOpacity(0.85)
                  : context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isSent ? null : Border.all(color: context.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VideoThumbnail(
                  videoUrl: message.video ?? '',
                  onTap: () {
                    if (message.video != null && message.video!.isNotEmpty) {
                      Get.to(() => VideoPlayerScreen(videoUrl: message.video!));
                    }
                  },
                  onLongPress: () {
                    if (message.video != null && message.video!.isNotEmpty) {
                      MediaDownloader.download(
                        url: message.video!,
                        fileName:
                            'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
                      );
                    }
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isSent ? Colors.white70 : context.textHintColor,
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
  bool isSent, {
  required String chatAvatar,
  required VoidCallback? onAccept,
  required VoidCallback? onReject,
  required VoidCallback? onCancel,
  required VoidCallback? onEdit,
}) {
  final currentUserId = Get.find<AuthService>().currentUser.value?.id;
  final isHelper = message.senderId == currentUserId;

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment:
          isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          _peerAvatar(chatAvatar),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: OfferCardWidget(
            message: message,
            isSentByMe: isSent,
            isHelper: isHelper,
            onAccept: onAccept,
            onReject: onReject,
            onCancel: onCancel,
            onEdit: onEdit ?? () {
              if (message.offerData == null) return;
            },
          ),
        ),
      ],
    ),
  );
}

void _saveImage(String url) {
  final ext = url.split('.').last.split('?').first;
  MediaDownloader.download(
    url: url,
    fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.$ext',
  );
}

Widget _buildImageGrid(BuildContext context, List<String> images) {
  final count = images.length.clamp(1, 4);

  if (count == 1) {
    return GestureDetector(
      onTap: () => Get.to(() => ImageViewerScreen(imageUrls: images, initialIndex: 0)),
      onLongPress: () => _saveImage(images[0]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          ApiConstants.resolveImageUrl(images[0]) ?? images[0],
          width: 200,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 250,
            color: context.inputFillColor,
            child: Icon(Icons.broken_image, color: context.textHintColor),
          ),
        ),
      ),
    );
  }

  return SizedBox(
    width: 220,
    child: count <= 2
        ? Row(
            children: List.generate(count, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < count - 1 ? 4 : 0),
                  child: GestureDetector(
                    onTap: () => Get.to(() => ImageViewerScreen(imageUrls: images, initialIndex: index)),
                    onLongPress: () => _saveImage(images[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(images[index]) ??
                            ApiConstants.resolveImageUrl(images[index]) ??
                                images[index],
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: context.inputFillColor,
                          child: Icon(Icons.broken_image, size: 20, color: context.textHintColor),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(2, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 0 ? 4 : 0, bottom: 4),
                      child: GestureDetector(
                        onTap: () => Get.to(() => ImageViewerScreen(imageUrls: images, initialIndex: index)),
                        onLongPress: () => _saveImage(images[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiConstants.resolveImageUrl(images[index]) ??
                            ApiConstants.resolveImageUrl(images[index]) ??
                                images[index],
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: context.inputFillColor,
                              child: Icon(Icons.broken_image, size: 20, color: context.textHintColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              Row(
                children: List.generate(count - 2, (i) {
                  final index = i + 2;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < count - 1 ? 4 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => Get.to(() => ImageViewerScreen(imageUrls: images, initialIndex: index)),
                        onLongPress: () => _saveImage(images[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiConstants.resolveImageUrl(images[index]) ??
                            ApiConstants.resolveImageUrl(images[index]) ??
                                images[index],
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 100,
                              color: context.inputFillColor,
                              child: Icon(Icons.broken_image, size: 20, color: context.textHintColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
  );
}

String _formatTime(DateTime dateTime) {
  final hour24 = dateTime.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}
