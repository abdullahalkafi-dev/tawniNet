import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/messages/controllers/chat_detail_controller.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_card_widget.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_form_bottom_sheet.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/upload_progress_dialog.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/video_player_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/video_thumbnail.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/media_downloader.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/video_compressor.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatDetailView extends StatefulWidget {
  const ChatDetailView({super.key});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  late final ChatDetailController chatController;
  late final ChatSummary chat;

  @override
  void initState() {
    super.initState();
    chat = Get.arguments as ChatSummary;
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

                  // Date separator + message (separator above, not instead of message)
                  if (index == 0 ||
                      !_isSameDay(
                        chatController.messages[index - 1].createdAt,
                        message.createdAt,
                      )) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDateSeparator(message.createdAt),
                        _buildMessageWidget(message, isSent),
                      ],
                    );
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

  void _saveImage(String url) {
    final ext = url.split('.').last.split('?').first;
    MediaDownloader.download(
      url: url,
      fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
  }

  Widget _buildImageGrid(List<String> images) {
    final count = images.length.clamp(1, 4);

    if (count == 1) {
      return GestureDetector(
        onTap: () => Get.to(() => ImageViewerScreen(imageUrls: images, initialIndex: 0)),
        onLongPress: () => _saveImage(images[0]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[0],
            width: 200,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 250,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    // Multi-image grid
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
                          images[index],
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 20),
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
                // Top row: 2 images
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
                              images[index],
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                // Bottom row: remaining images
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
                              images[index],
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 20),
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
                          fileName: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
                        );
                      }
                    },
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
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
        top: false,
        child: Row(
          children: [
            // Image picker button
            IconButton(
              icon: const Icon(Icons.image_outlined, color: AppColors.primary),
              onPressed: () => _showMediaOptions(),
            ),
            // Offer button
            IconButton(
              icon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
              onPressed: () => _showOfferForm(),
            ),
            const SizedBox(width: 8),
            // Text input
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
            // Send button
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
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Send Video'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);

    if (pickedFiles.isEmpty) return;

    // Limit to 4 images
    final files = pickedFiles.take(4).toList();

    try {
      final api = Get.find<ApiClient>();
      final imageKeys = <String>[];

      for (final file in files) {
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(file.path),
        });

        final response = await api.upload<dynamic>(
          ApiConstants.uploadImage,
          formData: formData,
        );

        if (response.success && response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['key'] != null) {
            imageKeys.add(data['key']);
          }
        } else {
          // If any image fails, abort all
          if (mounted) {
            Get.snackbar('Error', 'Failed to upload image ${imageKeys.length + 1}',
                snackPosition: SnackPosition.BOTTOM);
          }
          return;
        }
      }

      if (imageKeys.isNotEmpty) {
        chatController.sendImageMessage(imageKeys);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to upload images',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> _pickAndSendVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (pickedFile == null) return;

    final uploadProgress = 0.0.obs;
    final uploadStatus = 'Compressing video...'.obs;
    bool dialogShowing = false;
    File? compressed;

    try {
      // Show progress dialog IMMEDIATELY (before compression)
      UploadProgressDialog.show(progress: uploadProgress, status: uploadStatus);
      dialogShowing = true;

      // Compress video (dialog visible with "Compressing video...")
      compressed = await VideoCompressor.compress(pickedFile.path);
      final file = compressed ?? File(pickedFile.path);

      // Check compressed file size (400MB limit)
      final fileBytes = await file.length();
      if (fileBytes > 400 * 1024 * 1024) {
        if (dialogShowing && Get.isDialogOpen == true) {
          Get.back();
          dialogShowing = false;
        }
        Get.snackbar('Error', 'Video must be under 400MB',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      // Upload with progress
      uploadStatus.value = 'Uploading video...';
      final api = Get.find<ApiClient>();
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(file.path),
      });

      final response = await api.upload<dynamic>(
        ApiConstants.uploadVideo,
        formData: formData,
        onSendProgress: (sent, total) {
          uploadProgress.value = sent / total;
        },
      );

      if (dialogShowing && Get.isDialogOpen == true) {
        Get.back(); // Close progress dialog
        dialogShowing = false;
      }

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['key'] != null) {
          chatController.sendVideoMessage(data['key']);
        }
      } else {
        Get.snackbar('Error', 'Failed to upload video',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (dialogShowing && Get.isDialogOpen == true) {
        Get.back(); // Close progress dialog if open
      }
      if (mounted) {
        Get.snackbar('Error', 'Failed to upload video',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      // Clean up compressed temp file
      if (compressed != null) {
        try { await compressed.delete(); } catch (_) {}
      }
    }
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
