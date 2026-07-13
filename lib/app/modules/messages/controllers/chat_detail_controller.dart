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
  final onlineUsers = <String>{}.obs; // Set of online user IDs

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  String? _conversationId;
  Timer? _typingTimer;
  StreamSubscription? _messageSub;
  StreamSubscription? _typingStartSub;
  StreamSubscription? _typingStopSub;
  StreamSubscription? _presenceSub;

  String? get currentUserId => _authService.currentUser.value?.id;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiClient>();
    _authService = Get.find<AuthService>();
    _socketService = Get.find<SocketService>();
    _setupStreamListeners();
    _setupScrollListener();
  }

  @override
  void onClose() {
    if (_conversationId != null) {
      _socketService.leaveConversation(_conversationId!);
    }
    _typingTimer?.cancel();
    _messageSub?.cancel();
    _typingStartSub?.cancel();
    _typingStopSub?.cancel();
    _presenceSub?.cancel();
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
    if (isClosed) return;

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
            final currentUserId = _authService.currentUser.value?.id;
            return (data['docs'] as List)
                .map((e) {
                  final msg = ChatMessage.fromJson(e);
                  // Determine isSentByMe from sender field
                  final senderId = e['sender'] is Map
                      ? e['sender']['_id'] ?? ''
                      : e['sender'] ?? '';
                  return msg.copyWith(isSentByMe: senderId == currentUserId);
                })
                .toList();
          }
          return <ChatMessage>[];
        },
      );

      if (isClosed) return;

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
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to load messages',
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  /// Send a text message (REST only — socket is for receiving only).
  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    if (isClosed) return;

    messageController.clear();
    _stopTyping();

    // Add optimistic message with temp ID
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    messages.add(ChatMessage(
      id: tempId,
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'text',
      content: text,
      createdAt: DateTime.now(),
      isSentByMe: true,
    ));

    _scrollToBottom();

    // Send via REST
    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatMessages(_conversationId!),
        data: {
          'type': 'text',
          'content': text,
        },
      );

      if (isClosed) return;

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final realMessage = ChatMessage.fromJson(data).copyWith(isSentByMe: true);
          final idx = messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            messages[idx] = realMessage;
          }
        }
      } else {
        // Remove optimistic message on failure
        messages.removeWhere((m) => m.id == tempId);
        Get.snackbar('Error', 'Failed to send message', snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      if (!isClosed) {
        messages.removeWhere((m) => m.id == tempId);
        Get.snackbar('Error', 'Failed to send message', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  /// Send an image message (REST only).
  Future<void> sendImageMessage(List<String> imageKeys) async {
    if (imageKeys.isEmpty || _conversationId == null) return;
    if (isClosed) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    messages.add(ChatMessage(
      id: tempId,
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'image',
      images: imageKeys,
      createdAt: DateTime.now(),
      isSentByMe: true,
    ));

    _scrollToBottom();

    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatMessages(_conversationId!),
        data: {
          'type': 'image',
          'images': imageKeys,
        },
      );

      if (isClosed) return;

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final realMessage = ChatMessage.fromJson(data).copyWith(isSentByMe: true);
          final idx = messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            messages[idx] = realMessage;
          }
        }
      } else {
        messages.removeWhere((m) => m.id == tempId);
      }
    } catch (_) {
      if (!isClosed) {
        messages.removeWhere((m) => m.id == tempId);
      }
    }
  }

  /// Send a video message (REST only).
  Future<void> sendVideoMessage(String videoKey) async {
    if (videoKey.isEmpty || _conversationId == null) return;
    if (isClosed) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    messages.add(ChatMessage(
      id: tempId,
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'video',
      video: videoKey,
      createdAt: DateTime.now(),
      isSentByMe: true,
    ));

    _scrollToBottom();

    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatMessages(_conversationId!),
        data: {
          'type': 'video',
          'video': videoKey,
        },
      );

      if (isClosed) return;

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final realMessage = ChatMessage.fromJson(data).copyWith(isSentByMe: true);
          final idx = messages.indexWhere((m) => m.id == tempId);
          if (idx != -1) {
            messages[idx] = realMessage;
          }
        }
      } else {
        messages.removeWhere((m) => m.id == tempId);
      }
    } catch (_) {
      if (!isClosed) {
        messages.removeWhere((m) => m.id == tempId);
      }
    }
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
    if (isClosed) return;

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

      if (isClosed) return;

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          messages.add(ChatMessage.fromJson(data).copyWith(isSentByMe: true));
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to send offer',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  /// Accept an offer.
  Future<void> acceptOffer(String offerMessageId) async {
    if (_conversationId == null) return;
    if (isClosed) return;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferAccept(_conversationId!, offerMessageId),
      );

      if (isClosed) return;

      if (response.success) {
        _updateOfferStatus(offerMessageId, 'accepted');
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to accept offer',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  /// Reject an offer.
  Future<void> rejectOffer(String offerMessageId) async {
    if (_conversationId == null) return;
    if (isClosed) return;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferReject(_conversationId!, offerMessageId),
      );

      if (isClosed) return;

      if (response.success) {
        _updateOfferStatus(offerMessageId, 'rejected');
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to reject offer',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  /// Cancel/withdraw an offer (helper only).
  Future<void> cancelOffer(String offerMessageId) async {
    if (_conversationId == null) return;
    if (isClosed) return;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferCancel(_conversationId!, offerMessageId),
      );

      if (isClosed) return;

      if (response.success) {
        _updateOfferStatus(offerMessageId, 'cancelled');
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to cancel offer',
            snackPosition: SnackPosition.BOTTOM);
      }
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
    if (isClosed) return;

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

      if (isClosed) return;

      if (response.success && response.data != null) {
        final idx = messages.indexWhere((m) => m.id == offerMessageId);
        if (idx != -1) {
          messages[idx] = ChatMessage.fromJson(response.data!)
              .copyWith(isSentByMe: true);
        }
      }
    } catch (e) {
      if (!isClosed) {
        Get.snackbar('Error', 'Failed to edit offer',
            snackPosition: SnackPosition.BOTTOM);
      }
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

  void _setupStreamListeners() {
    // Listen for new messages via stream
    _messageSub = _socketService.onNewMessage.listen((message) {
      if (isClosed) return;
      if (message.conversationId == _conversationId) {
        if (message.senderId != currentUserId) {
          messages.add(message);
          _scrollToBottom();
        }
      }
    });

    // Listen for typing start
    _typingStartSub = _socketService.onTypingStart.listen((data) {
      if (isClosed) return;
      if (data['conversationId'] == _conversationId &&
          data['userId'] != currentUserId) {
        isTyping.value = true;
      }
    });

    // Listen for typing stop
    _typingStopSub = _socketService.onTypingStop.listen((data) {
      if (isClosed) return;
      if (data['conversationId'] == _conversationId &&
          data['userId'] != currentUserId) {
        isTyping.value = false;
      }
    });

    // Listen for presence updates
    _presenceSub = _socketService.onPresenceUpdate.listen((data) {
      if (isClosed) return;
      final userId = data['userId'] as String? ?? '';
      final isOnline = data['isOnline'] as bool? ?? false;
      if (isOnline) {
        onlineUsers.add(userId);
      } else {
        onlineUsers.remove(userId);
      }
    });
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
