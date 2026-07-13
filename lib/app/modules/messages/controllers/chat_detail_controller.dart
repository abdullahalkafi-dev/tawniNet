import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';

class ChatDetailController extends GetxController {
  late final ApiClient _api;
  late final AuthService _authService;
  late final SocketService _socketService;

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isTyping = false.obs;
  final hasMore = true.obs;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  String? _conversationId;
  Timer? _typingTimer;

  String? get currentUserId => _authService.currentUser.value?.id;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiClient>();
    _authService = Get.find<AuthService>();
    _socketService = Get.find<SocketService>();
    _setupSocketListeners();
    _setupScrollListener();
  }

  @override
  void onClose() {
    if (_conversationId != null) {
      _socketService.leaveConversation(_conversationId!);
    }
    _typingTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Initialize with conversation data from arguments.
  void initConversation(String conversationId, String otherParticipantId) {
    _conversationId = conversationId;

    _socketService.joinConversation(conversationId);
    fetchMessages();
  }

  /// Fetch messages from API.
  Future<void> fetchMessages({bool loadMore = false}) async {
    if (_conversationId == null) return;

    if (loadMore) {
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final query = <String, dynamic>{
        'page': loadMore ? (messages.length ~/ 20 + 1) : 1,
        'limit': 20,
      };

      if (loadMore && messages.isNotEmpty) {
        query['before'] = messages.first.createdAt.toIso8601String();
      }

      final response = await _api.get<List<ChatMessage>>(
        ApiConstants.chatMessages(_conversationId!),
        queryParameters: query,
        fromData: (data) {
          if (data is Map<String, dynamic> && data['docs'] is List) {
            return (data['docs'] as List)
                .map((e) => ChatMessage.fromJson(e).copyWith(
                      isSentByMe: e['sender'] == currentUserId ||
                          (e['sender'] is Map &&
                              e['sender']['_id'] == currentUserId),
                    ))
                .toList();
          }
          return <ChatMessage>[];
        },
      );

      if (response.success && response.data != null) {
        if (loadMore) {
          messages.insertAll(0, response.data!);
        } else {
          messages.assignAll(response.data!);
        }

        if (response.meta != null) {
          hasMore.value = messages.length < response.meta!.total;
        }
      }
    } catch (e) {
      // Silent fail
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Send a text message.
  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    messageController.clear();
    _stopTyping();

    // Send via socket for real-time
    _socketService.sendMessage(
      conversationId: _conversationId!,
      type: 'text',
      content: text,
    );

    // Add optimistic message
    messages.add(ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'text',
      content: text,
      createdAt: DateTime.now(),
      isSentByMe: true,
    ));

    _scrollToBottom();
  }

  /// Send an image message.
  Future<void> sendImageMessage(List<String> imageKeys) async {
    if (imageKeys.isEmpty || _conversationId == null) return;

    _socketService.sendMessage(
      conversationId: _conversationId!,
      type: 'image',
      images: imageKeys,
    );

    messages.add(ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'image',
      images: imageKeys,
      createdAt: DateTime.now(),
      isSentByMe: true,
    ));

    _scrollToBottom();
  }

  /// Send a video message.
  Future<void> sendVideoMessage(String videoKey) async {
    if (videoKey.isEmpty || _conversationId == null) return;

    _socketService.sendMessage(
      conversationId: _conversationId!,
      type: 'video',
      video: videoKey,
    );

    messages.add(ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'video',
      video: videoKey,
      createdAt: DateTime.now(),
      isSentByMe: true,
    ));

    _scrollToBottom();
  }

  /// Send a service offer.
  Future<void> sendOffer({
    required String title,
    String? description,
    required double price,
    String priceType = 'fixed',
    String? startTime,
    String? endTime,
    String paymentMethod = 'cash',
    List<String>? images,
  }) async {
    if (_conversationId == null) return;

    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatOffer(_conversationId!),
        data: {
          'title': title,
          if (description != null) 'description': description,
          'price': price,
          'priceType': priceType,
          if (startTime != null) 'startTime': startTime,
          if (endTime != null) 'endTime': endTime,
          'paymentMethod': paymentMethod,
          if (images != null) 'images': images,
        },
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          messages.add(ChatMessage.fromJson(data).copyWith(isSentByMe: true));
          _scrollToBottom();
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Accept an offer.
  Future<void> acceptOffer(String offerMessageId) async {
    if (_conversationId == null) return;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferAccept(_conversationId!, offerMessageId),
      );

      if (response.success) {
        // Update offer status in messages list
        _updateOfferStatus(offerMessageId, 'accepted');
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Reject an offer.
  Future<void> rejectOffer(String offerMessageId) async {
    if (_conversationId == null) return;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferReject(_conversationId!, offerMessageId),
      );

      if (response.success) {
        _updateOfferStatus(offerMessageId, 'rejected');
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Cancel/withdraw an offer (helper only).
  Future<void> cancelOffer(String offerMessageId) async {
    if (_conversationId == null) return;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferCancel(_conversationId!, offerMessageId),
      );

      if (response.success) {
        _updateOfferStatus(offerMessageId, 'cancelled');
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Edit an offer (helper only, before acceptance).
  Future<void> editOffer(
    String offerMessageId, {
    String? title,
    String? description,
    double? price,
    String? priceType,
    String? startTime,
    String? endTime,
    String? paymentMethod,
    List<String>? images,
  }) async {
    if (_conversationId == null) return;

    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (priceType != null) data['priceType'] = priceType;
      if (startTime != null) data['startTime'] = startTime;
      if (endTime != null) data['endTime'] = endTime;
      if (paymentMethod != null) data['paymentMethod'] = paymentMethod;
      if (images != null) data['images'] = images;

      final response = await _api.patch<Map<String, dynamic>>(
        ApiConstants.chatOfferEdit(_conversationId!, offerMessageId),
        data: data,
      );

      if (response.success && response.data != null) {
        // Update message in list
        final idx = messages.indexWhere((m) => m.id == offerMessageId);
        if (idx != -1) {
          messages[idx] = ChatMessage.fromJson(response.data!)
              .copyWith(isSentByMe: true);
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  // ─── Private Helpers ─────────────────────────────────

  void _updateOfferStatus(String messageId, String status) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final oldMsg = messages[idx];
      if (oldMsg.offerData != null) {
        messages[idx] = ChatMessage(
          id: oldMsg.id,
          conversationId: oldMsg.conversationId,
          senderId: oldMsg.senderId,
          type: oldMsg.type,
          content: oldMsg.content,
          images: oldMsg.images,
          video: oldMsg.video,
          offerData: OfferData(
            title: oldMsg.offerData!.title,
            description: oldMsg.offerData!.description,
            price: oldMsg.offerData!.price,
            priceType: oldMsg.offerData!.priceType,
            startTime: oldMsg.offerData!.startTime,
            endTime: oldMsg.offerData!.endTime,
            paymentMethod: oldMsg.offerData!.paymentMethod,
            images: oldMsg.offerData!.images,
            status: status,
          ),
          createdAt: oldMsg.createdAt,
          isSentByMe: oldMsg.isSentByMe,
        );
      }
    }
  }

  void _setupSocketListeners() {
    _socketService.onNewMessage = (message) {
      if (message.conversationId == _conversationId) {
        // Don't add if it's our own message (already added optimistically)
        if (message.senderId != currentUserId) {
          messages.add(message);
          _scrollToBottom();
        }
      }
    };

    _socketService.onTypingStart = (convId, userId) {
      if (convId == _conversationId && userId != currentUserId) {
        isTyping.value = true;
      }
    };

    _socketService.onTypingStop = (convId, userId) {
      if (convId == _conversationId && userId != currentUserId) {
        isTyping.value = false;
      }
    };

    _socketService.onMessagesRead = (userId, messageIds) {
      // Could update read receipts here if needed
    };
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (hasMore.value && !isLoadingMore.value) {
          fetchMessages(loadMore: true);
        }
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTyping() {
    if (_conversationId == null) return;
    _socketService.startTyping(_conversationId!);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTyping();
    });
  }

  void _stopTyping() {
    if (_conversationId == null) return;
    _socketService.stopTyping(_conversationId!);
    _typingTimer?.cancel();
  }

  void onTextChanged(String text) {
    if (text.isNotEmpty) {
      _startTyping();
    } else {
      _stopTyping();
    }
  }
}
