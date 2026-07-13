import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/chat_detail_controller.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_card_widget.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_form_bottom_sheet.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperChatDetailView extends StatefulWidget {
  const HelperChatDetailView({super.key});

  @override
  State<HelperChatDetailView> createState() => _HelperChatDetailViewState();
}

class _HelperChatDetailViewState extends State<HelperChatDetailView> {
  late final ChatDetailController chatController;
  final ChatSummary chat = Get.arguments;

  @override
  void initState() {
    super.initState();
    chatController = Get.put(ChatDetailController());
    chatController.initConversation(chat.id, chat.id);
  }

  @override
  void dispose() {
    Get.delete<ChatDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Column(
          children: [
            Text(
              chat.name,
              style: AppStyles.h2.copyWith(color: Colors.black, fontSize: 18),
            ),
            Obx(() {
              if (chatController.isTyping.value) {
                return Text(
                  'Typing...',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (chatController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (chatController.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Say hello!',
                    style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                controller: chatController.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  final message = chatController.messages[index];
                  final isSent = message.isSentByMe;

                  if (index == 0 ||
                      !_isSameDay(
                        chatController.messages[index - 1].createdAt,
                        message.createdAt,
                      )) {
                    return _buildDateSeparator(message.createdAt);
                  }

                  return _buildMessageWidget(message, isSent);
                },
              );
            }),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
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
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.blue[300],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWidget(ChatMessage message, bool isSent) {
    switch (message.type) {
      case 'image':
        return _buildImageMessage(message, isSent);
      case 'video':
        return _buildVideoMessage(message, isSent);
      case 'offer':
        return _buildOfferMessage(message, isSent);
      default:
        return _buildTextMessage(message, isSent);
    }
  }

  Widget _buildTextMessage(ChatMessage message, bool isSent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: chat.image.isNotEmpty
                  ? NetworkImage(chat.image)
                  : null,
              child: chat.image.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
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
                  bottomLeft:
                      isSent ? const Radius.circular(16) : Radius.zero,
                  bottomRight:
                      isSent ? Radius.zero : const Radius.circular(16),
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

  Widget _buildImageMessage(ChatMessage message, bool isSent) {
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
            CircleAvatar(
              radius: 16,
              backgroundImage: chat.image.isNotEmpty
                  ? NetworkImage(chat.image)
                  : null,
              child: chat.image.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
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

  Widget _buildVideoMessage(ChatMessage message, bool isSent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: chat.image.isNotEmpty
                  ? NetworkImage(chat.image)
                  : null,
              child: chat.image.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
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
                  Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
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

  Widget _buildOfferMessage(ChatMessage message, bool isSent) {
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
            CircleAvatar(
              radius: 16,
              backgroundImage: chat.image.isNotEmpty
                  ? NetworkImage(chat.image)
                  : null,
              child: chat.image.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: OfferCardWidget(
              message: message,
              isSentByMe: isSent,
              isHelper: isHelper,
              onAccept: () => chatController.acceptOffer(message.id),
              onReject: () => chatController.rejectOffer(message.id),
              onCancel: () => chatController.cancelOffer(message.id),
              onEdit: () => _showEditOfferSheet(message),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditOfferSheet(ChatMessage message) {
    if (message.offerData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFormBottomSheet(
        conversationId: chat.id,
        editOffer: message.offerData,
        onOfferSent: (data) {
          chatController.editOffer(
            message.id,
            title: data['title'],
            description: data['description'],
            price: data['price']?.toDouble(),
            priceType: data['priceType'],
            startTime: data['startTime'],
            endTime: data['endTime'],
            paymentMethod: data['paymentMethod'],
            images: data['images']?.cast<String>(),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.primary),
              onPressed: () => _showMediaOptions(),
            ),
            IconButton(
              icon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
              onPressed: () => _showOfferForm(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: chatController.messageController,
                  onChanged: chatController.onTextChanged,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'label_type_message'.tr,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: chatController.sendTextMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Send Image'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick and upload images
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Send Video'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Pick and upload video
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFormBottomSheet(
        conversationId: chat.id,
        onOfferSent: (data) {
          chatController.sendOffer(
            title: data['title'],
            description: data['description'],
            price: (data['price'] ?? 0).toDouble(),
            priceType: data['priceType'] ?? 'fixed',
            startTime: data['startTime'],
            endTime: data['endTime'],
            paymentMethod: data['paymentMethod'] ?? 'cash',
            images: data['images']?.cast<String>(),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
