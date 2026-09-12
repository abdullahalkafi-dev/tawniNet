import 'dart:io';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/support_media.dart';
import 'package:awnneaapp/app/modules/helper/settings/controllers/customer_service_controller.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/video_compressor.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CustomerServiceView extends StatefulWidget {
  const CustomerServiceView({super.key});

  @override
  State<CustomerServiceView> createState() => _CustomerServiceViewState();
}

class _CustomerServiceViewState extends State<CustomerServiceView> {
  final messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<File> _selectedMedia = [];
  bool _isUploading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMediaOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: context.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppColors.primary),
                title: const Text('Send Image'),
                subtitle: const Text('Select up to 4 images'),
                onTap: () {
                  Get.back();
                  _pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: AppColors.primary),
                title: const Text('Send Video'),
                subtitle: const Text('Max 5 minutes, 400MB'),
                onTap: () {
                  Get.back();
                  _pickVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(images.take(4).map((x) => File(x.path)));
        });
      }
    } catch (e) {
      AppFeedback.error('Failed to pick images');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (pickedFile == null) return;

      final fileBytes = await File(pickedFile.path).length();
      if (fileBytes > 400 * 1024 * 1024) {
        AppFeedback.error('Video must be under 400MB');
        return;
      }

      setState(() => _isUploading = true);

      final compressed = await VideoCompressor.compress(pickedFile.path);
      final file = compressed ?? File(pickedFile.path);

      final key = await _uploadSingleFile(file, ApiConstants.uploadVideo);
      if (key != null) {
        final controller = Get.find<CustomerServiceController>();
        await controller.sendImageMessage([key]);
        _scrollToBottom();
      }

      if (compressed != null) {
        try { await compressed.delete(); } catch (_) {}
      }
    } catch (e) {
      AppFeedback.error('Failed to upload video');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
  }

  Future<String?> _uploadSingleFile(File file, String endpoint) async {
    try {
      final apiClient = Get.find<ApiClient>();
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(file.path),
      });
      final response = await apiClient.upload(
        endpoint,
        formData: formData,
        fromData: (data) => data,
      );
      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final key = data['key'] ?? data['path'] ?? data['url'] ?? '';
        if (key.toString().isNotEmpty) return key.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedMedia.isEmpty) return [];
    setState(() => _isUploading = true);

    try {
      final keys = <String>[];
      for (final image in _selectedMedia) {
        final key = await _uploadSingleFile(image, ApiConstants.uploadImage);
        if (key != null) keys.add(key);
      }
      return keys;
    } catch (e) {
      return [];
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage() async {
    final controller = Get.find<CustomerServiceController>();
    final text = messageController.text;

    if (_selectedMedia.isNotEmpty) {
      final mediaKeys = await _uploadImages();
      if (mediaKeys.isNotEmpty) {
        await controller.sendImageMessage(mediaKeys);
        if (mounted) {
          setState(() => _selectedMedia.clear());
          _scrollToBottom();
        }
      }
    }

    if (text.isNotEmpty) {
      messageController.clear();
      await controller.sendMessage(text);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerServiceController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings_contact_us'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.selectedTicketId.value.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 48, color: context.textHintColor),
                        const SizedBox(height: 12),
                        Text(
                          'Select a ticket from the list to continue the conversation.',
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyMediumOf(context)
                              .copyWith(color: context.textSecondaryColor),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Back to tickets'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final msgs = controller.messages;
              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Send a message to contact support.'.tr,
                    style: AppStyles.bodyMediumOf(context)
                        .copyWith(color: context.textSecondaryColor),
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];
                  final isSent = (msg['senderRole'] ?? msg['role']) != 'admin';
                  final attachments = (msg['attachments'] as List<dynamic>?) ?? [];
                  return _buildMessageBubble(
                    context: context,
                    text: msg['content'] ?? msg['text'] ?? '',
                    isSent: isSent,
                    time: msg['createdAt'] != null
                        ? msg['createdAt'].toString().substring(11, 16)
                        : 'Now',
                    attachments: attachments.cast<String>(),
                  );
                },
              );
            }),
          ),
          Obx(() {
            if (controller.selectedTicketId.value.isEmpty) {
              return const SizedBox.shrink();
            }
            if (controller.isResolved) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  border: Border(top: BorderSide(color: context.borderSubtle)),
                ),
                child: Column(
                  children: [
                    Text(
                      'This ticket is resolved.',
                      style: AppStyles.bodyMediumOf(context).copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a new ticket if you need more help.',
                      style: AppStyles.bodySmallOf(context).copyWith(
                        color: context.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                        },
                        child: const Text('Back to tickets'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return _buildInputSection(context, controller);
          }),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required String text,
    required bool isSent,
    required String time,
    List<String> attachments = const [],
  }) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildMediaGrid(context, attachments),
              ),
            if (text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isSent ? AppColors.primary : context.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSent ? 16 : 0),
                    bottomRight: Radius.circular(isSent ? 0 : 16),
                  ),
                  border: isSent ? null : Border.all(color: context.borderSubtle),
                ),
                child: Text(
                  text,
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    color: isSent ? Colors.white : context.textPrimaryColor,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppStyles.bodySmallOf(context)
                  .copyWith(fontSize: 10, color: context.textHintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<String> mediaUrls) {
    return SupportMediaGrid(urls: mediaUrls);
  }

  Widget _buildInputSection(BuildContext context, CustomerServiceController controller) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          border: Border(top: BorderSide(color: context.borderSubtle)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedMedia.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedMedia[index],
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: _isUploading ? null : _showMediaOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'chat_type_message'.tr,
                      hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                if (controller.isSending.value || _isUploading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _sendMessage,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
