import 'dart:io';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/messages/controllers/chat_detail_controller.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_card_widget.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/offer_form_bottom_sheet.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/video_player_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/video_thumbnail.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/media_downloader.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/core/widgets/emoji_picker_panel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awnneaapp/app/core/utils/image_picker_errors.dart';

/// The one chat screen, used by clients and helpers alike.
class ChatDetailView extends StatefulWidget {
  const ChatDetailView({super.key});

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  late final ChatDetailController chatController;
  late ChatSummary chat;

  @override
  void initState() {
    super.initState();
    // Accept ChatSummary (normal nav) or conversationId String (push deep-link).
    final args = Get.arguments;
    if (args is ChatSummary) {
      chat = args;
      chatController = Get.put(ChatDetailController());
      chatController.initConversation(chat.id, chat.otherUserId);
    } else if (args is String) {
      chat = ChatSummary(id: args, name: 'btn_chat'.tr, image: '');
      chatController = Get.put(ChatDetailController());
      chatController.initConversation(chat.id, '');
      _resolveChatMeta(args);
    } else {
      chat = ChatSummary(id: '', name: 'btn_chat'.tr, image: '');
      chatController = Get.put(ChatDetailController());
    }
  }

  Future<void> _resolveChatMeta(String conversationId) async {
    try {
      final messages = Get.find<MessagesController>();
      final summary = await messages.resolveChatSummary(conversationId);
      if (summary != null && mounted) {
        setState(() {
          chat = summary;
        });
        if (summary.otherUserId.isNotEmpty) {
          chatController.initConversation(summary.id, summary.otherUserId);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (chat.id.isNotEmpty && Get.isRegistered<MessagesController>()) {
      Get.find<MessagesController>().markConversationReadLocally(chat.id);
    }
    Get.delete<ChatDetailController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep input above keyboard + 3-button nav on Android.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            AppAvatar(url: chat.image, name: chat.name, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                  ),
                  Obx(() {
                    final typing = chatController.isTyping.value;
                    final online = chatController.isOtherOnline;
                    return Text(
                      typing
                          ? 'ui_typing'.tr
                          : online
                              ? 'chat_online'.tr
                              : 'chat_offline'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: (typing || online) ? AppColors.primary : context.textHintColor,
                        fontSize: 12,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') {
                  chatController.setBlocked(!chatController.isBlocked.value);
                } else if (value == 'report') {
                  _showReportSheet();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    chatController.isBlocked.value ? 'chat_unblock'.tr : 'chat_block'.tr,
                  ),
                ),
                PopupMenuItem(value: 'report', child: Text('chat_report'.tr)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageArea(context)),
          _buildInputOrBlocked(context),
        ],
      ),
    );
  }

  Widget _buildMessageArea(BuildContext context) {
    return Stack(
      children: [
        Obx(() {
          if (chatController.isLoading.value && chatController.messages.isEmpty) {
            return const _ChatSkeleton();
          }

          if (chatController.loadFailed.value && chatController.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 40, color: context.textHintColor),
                  const SizedBox(height: 12),
                  Text('ui_failed_to_load_messages'.tr,
                      style: AppStyles.bodyMedium.copyWith(color: context.textHintColor)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: chatController.fetchMessages,
                    icon: const Icon(Icons.refresh),
                    label: Text('booking_retry'.tr),
                  ),
                ],
              ),
            );
          }

          if (chatController.messages.isEmpty) {
            return Center(
              child: Text(
                'ui_no_messages_yet_say_hello'.tr,
                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              ),
            );
          }

          final messages = chatController.messages;
          return ListView.builder(
            controller: chatController.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: messages.length + (chatController.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, rawIndex) {
              if (chatController.isLoadingMore.value) {
                if (rawIndex == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
              }
              final index = chatController.isLoadingMore.value ? rawIndex - 1 : rawIndex;
              final message = messages[index];
              final isSent = message.isSentByMe;
              final showSeparator = index == 0 ||
                  !_isSameDay(messages[index - 1].createdAt, message.createdAt);

              if (showSeparator) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDateSeparator(context, message.createdAt),
                    _buildMessageWidget(context, message, isSent),
                  ],
                );
              }
              return _buildMessageWidget(context, message, isSent);
            },
          );
        }),
        // "New messages ↓" while reading older ones
        PositionedDirectional(
          bottom: 12,
          end: 16,
          child: Obx(() {
            final count = chatController.newBelowCount.value;
            if (chatController.isNearBottom.value && count == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: chatController.scrollToLatest,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: count > 0 ? 14 : 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (count > 0)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Text(
                          'chat_new_messages'.trParams({'n': '$count'}),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInputOrBlocked(BuildContext context) {
    return Obx(() {
      if (chatController.isBlocked.value) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.of(context).viewPadding.bottom),
          color: context.cardColor,
          child: Row(
            children: [
              Icon(Icons.block, color: context.textHintColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'chat_conversation_blocked'.tr,
                  style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                ),
              ),
              TextButton(
                onPressed: () => chatController.setBlocked(false),
                child: Text('chat_unblock'.tr),
              ),
            ],
          ),
        );
      }
      return _buildInputBar(context);
    });
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String label;
    if (messageDate == today) {
      label = 'chat_today'.tr;
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      label = 'label_yesterday'.tr;
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
                ? AppColors.primary.withValues(alpha: 0.15)
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

  Widget _buildMessageWidget(BuildContext context, ChatMessage message, bool isSent) {
    final bubble = switch (message.type) {
      'image' => _buildImageMessage(context, message, isSent),
      'video' => _buildVideoMessage(context, message, isSent),
      'offer' => _buildOfferMessage(context, message, isSent),
      _ => _buildTextMessage(context, message, isSent),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _wrapRow(bubble, isSent),
          if (isSent && message.delivery == MessageDelivery.failed)
            _buildFailedActions(context, message),
        ],
      ),
    );
  }

  /// Bubble + (for incoming messages) the sender's avatar.
  Widget _wrapRow(Widget bubble, bool isSent) {
    return Row(
      mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isSent) ...[
          AppAvatar(url: chat.image, name: chat.name, size: 32),
          const SizedBox(width: 8),
        ],
        Flexible(child: bubble),
      ],
    );
  }

  BoxDecoration _bubbleDecoration(BuildContext context, bool isSent, {bool failed = false}) {
    return BoxDecoration(
      color: failed
          ? Colors.red.withValues(alpha: 0.55)
          : isSent
              ? AppColors.primary.withValues(alpha: 0.85)
              : context.inputFillLight,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: isSent ? const Radius.circular(16) : Radius.zero,
        bottomRight: isSent ? Radius.zero : const Radius.circular(16),
      ),
    );
  }

  /// Time + delivery marks: ⏱ sending, ✓ sent, ✓✓ read, ! failed.
  Widget _buildMeta(BuildContext context, ChatMessage message, bool isSent) {
    final color = isSent ? Colors.white70 : context.textHintColor;
    Widget? mark;
    if (isSent) {
      switch (message.delivery) {
        case MessageDelivery.sending:
          mark = Icon(Icons.access_time, size: 12, color: color);
          break;
        case MessageDelivery.failed:
          mark = const Icon(Icons.error_outline, size: 13, color: Colors.white);
          break;
        case MessageDelivery.sent:
          final other = chatController.otherParticipantId;
          final read = other != null && message.readBy.contains(other);
          mark = Icon(read ? Icons.done_all : Icons.done,
              size: 14, color: read ? Colors.lightBlueAccent.shade100 : color);
          break;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatTime(message.createdAt), style: TextStyle(color: color, fontSize: 10)),
        if (mark != null) ...[const SizedBox(width: 4), mark],
      ],
    );
  }

  Widget _buildFailedActions(BuildContext context, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message.errorText ?? 'ui_failed_to_send_message'.tr,
              style: const TextStyle(color: Colors.red, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => chatController.retryMessage(message.id),
            child: Text('booking_retry'.tr, style: const TextStyle(fontSize: 12)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: Colors.grey,
            ),
            onPressed: () => chatController.discardMessage(message.id, restoreText: true),
            child: Text('chat_delete_failed'.tr, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context, ChatMessage message, bool isSent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _bubbleDecoration(context, isSent,
          failed: message.delivery == MessageDelivery.failed),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              message.content ?? '',
              style: TextStyle(
                color: isSent ? Colors.white : context.textPrimaryColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (message.masked)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'chat_masked_notice'.tr,
                  style: TextStyle(
                    color: isSent ? Colors.white70 : context.textHintColor,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          _buildMeta(context, message, isSent),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context, ChatMessage message, bool isSent) {
    final remote = message.images;
    final local = message.localFiles;
    if (remote.isEmpty && local.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: message.delivery == MessageDelivery.failed
            ? Colors.red.withValues(alpha: 0.55)
            : isSent
                ? AppColors.primary.withValues(alpha: 0.85)
                : context.inputFillLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              _buildImageGrid(context, remote, local),
              if (message.delivery == MessageDelivery.sending)
                Obx(() {
                  final p = chatController.uploadProgress[message.id];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: p,
                        color: Colors.white,
                      ),
                    ),
                  );
                }),
            ],
          ),
          const SizedBox(height: 4),
          _buildMeta(context, message, isSent),
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

  /// Photos in a bubble: from the server (cached) or, while sending, from the device.
  Widget _buildImageGrid(BuildContext context, List<String> images, List<String> localFiles) {
    final isLocal = images.isEmpty;
    final total = isLocal ? localFiles.length : images.length;
    final count = total.clamp(1, 4);

    Widget tile(int index, {required double height, double? width}) {
      final child = isLocal
          ? Image.file(File(localFiles[index]),
              width: width, height: height, fit: BoxFit.cover, cacheWidth: 600)
          : AppNetworkImage(
              url: images[index],
              width: width ?? 110,
              height: height,
              errorWidget: Container(
                width: width,
                height: height,
                color: context.inputFillColor,
                child: Icon(Icons.broken_image, color: context.textHintColor),
              ),
            );
      return GestureDetector(
        onTap: isLocal
            ? null
            : () => Get.to(() => ImageViewerScreen(imageUrls: images, initialIndex: index)),
        onLongPress: isLocal ? null : () => _saveImage(images[index]),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
      );
    }

    if (count == 1) return tile(0, height: 250, width: 200);

    if (count == 2) {
      return SizedBox(
        width: 220,
        child: Row(
          children: List.generate(2, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: i == 0 ? 4 : 0),
                child: tile(i, height: 150),
              ),
            );
          }),
        ),
      );
    }

    return SizedBox(
      width: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(2, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: i == 0 ? 4 : 0, bottom: 4),
                  child: tile(i, height: 100),
                ),
              );
            }),
          ),
          Row(
            children: List.generate(count - 2, (i) {
              final index = i + 2;
              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: index < count - 1 ? 4 : 0),
                  child: tile(index, height: 100),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoMessage(BuildContext context, ChatMessage message, bool isSent) {
    final isLocal = (message.video ?? '').isEmpty;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: message.delivery == MessageDelivery.failed
            ? Colors.red.withValues(alpha: 0.55)
            : isSent
                ? AppColors.primary.withValues(alpha: 0.85)
                : context.inputFillLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isLocal)
            Obx(() {
              final p = chatController.uploadProgress[message.id];
              return Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: message.delivery == MessageDelivery.failed
                    ? const Icon(Icons.videocam_off, color: Colors.white70, size: 32)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, value: p, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p == null ? 'ui_compressing_video'.tr : 'ui_uploading_video'.tr,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
              );
            })
          else
            VideoThumbnail(
              videoUrl: message.video!,
              onTap: () => Get.to(() => VideoPlayerScreen(videoUrl: message.video!)),
              onLongPress: () => MediaDownloader.download(
                url: message.video!,
                fileName: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
              ),
            ),
          const SizedBox(height: 4),
          _buildMeta(context, message, isSent),
        ],
      ),
    );
  }

  Widget _buildOfferMessage(BuildContext context, ChatMessage message, bool isSent) {
    final currentUserId = Get.find<AuthService>().currentUser.value?.id;
    final isHelper = message.senderId == currentUserId;

    return OfferCardWidget(
      message: message,
      isSentByMe: isSent,
      isHelper: isHelper,
      onAccept: () => chatController.acceptOffer(message.id),
      onReject: () => chatController.rejectOffer(message.id),
      onCancel: () => chatController.cancelOffer(message.id),
      onEdit: () => _showEditOfferSheet(message),
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
        onOfferSent: (data) => chatController.editOffer(
          message.id,
          title: data['title'],
          description: data['description'],
          price: (data['price'] as num?)?.toDouble(),
          priceType: data['priceType'],
          date: data['date'],
          startTime: data['startTime'],
          endTime: data['endTime'],
          address: data['address'],
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          paymentMethod: data['paymentMethod'],
          images: (data['images'] as List?)?.cast<String>(),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final systemBottom = MediaQuery.of(context).viewPadding.bottom;
    // When keyboard is open Scaffold already insets; only pad for system nav.
    final bottomPad = bottomInset > 0 ? 8.0 : (systemBottom > 0 ? systemBottom : 8.0);

    return Container(
      padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: bottomPad),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppColors.primary),
            onPressed: _showMediaOptions,
          ),
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: AppColors.primary),
            onPressed: () => _showEmojiPicker(context),
          ),
          // Offers are sent by helpers only
          if (Get.find<RoleService>().isHelper)
            IconButton(
              icon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
              onPressed: _showOfferForm,
            ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.inputFillLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: chatController.messageController,
                onChanged: chatController.onTextChanged,
                style: TextStyle(color: context.textPrimaryColor),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'label_type_message'.tr,
                  hintStyle: TextStyle(color: context.textHintColor),
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
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EmojiPickerPanel(
        controller: chatController.messageController,
      ),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: Text('ui_take_photo'.tr),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendCameraPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: Text('ui_choose_from_gallery'.tr),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndSendImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.primary),
              title: Text('ui_send_video'.tr),
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

  Future<void> _pickAndSendCameraPhoto() async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
    } catch (e) {
      AppFeedback.error(imagePickerErrorMessage(e));
      return;
    }
    if (file == null) return;
    await chatController.sendImageFiles([file.path]);
  }

  Future<void> _pickAndSendImages() async {
    final List<XFile> pickedFiles;
    try {
      pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 80);
    } catch (e) {
      AppFeedback.error(imagePickerErrorMessage(e));
      return;
    }
    if (pickedFiles.isEmpty) return;
    await chatController.sendImageFiles(pickedFiles.take(4).map((f) => f.path).toList());
  }

  Future<void> _pickAndSendVideo() async {
    final XFile? pickedFile;
    try {
      pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
    } catch (e) {
      AppFeedback.error(imagePickerErrorMessage(e));
      return;
    }
    if (pickedFile == null) return;
    await chatController.sendVideoFile(pickedFile.path);
  }

  void _showOfferForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFormBottomSheet(
        conversationId: chat.id,
        onOfferSent: (data) => chatController.sendOffer(
          title: data['title'],
          description: data['description'],
          price: ((data['price'] ?? 0) as num).toDouble(),
          priceType: data['priceType'] ?? 'fixed',
          date: data['date'],
          startTime: data['startTime'],
          endTime: data['endTime'],
          address: data['address'],
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          paymentMethod: data['paymentMethod'] ?? 'cash',
          images: (data['images'] as List?)?.cast<String>(),
        ),
      ),
    );
  }

  void _showReportSheet() {
    const reasons = ['spam', 'harassment', 'fraud', 'inappropriate', 'other'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('chat_report'.tr, style: AppStyles.h2Of(ctx).copyWith(fontSize: 16)),
            ),
            for (final r in reasons)
              ListTile(
                title: Text('chat_report_$r'.tr),
                onTap: () {
                  Navigator.pop(ctx);
                  chatController.reportConversation(r);
                },
              ),
          ],
        ),
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

/// Placeholder bubbles while the first page of messages loads.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bubble({required bool mine, required double w, double h = 44}) => Align(
          alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: SkeletonBox(width: w, height: h, radius: 16),
        );
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          bubble(mine: false, w: 180),
          const SizedBox(height: 12),
          bubble(mine: true, w: 140),
          const SizedBox(height: 12),
          bubble(mine: false, w: 230, h: 64),
          const SizedBox(height: 12),
          bubble(mine: true, w: 200, h: 52),
          const SizedBox(height: 12),
          bubble(mine: false, w: 120),
          const SizedBox(height: 12),
          bubble(mine: true, w: 170),
        ],
      ),
    );
  }
}
