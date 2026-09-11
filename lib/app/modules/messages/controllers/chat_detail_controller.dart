import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';

class ChatDetailController extends GetxController {
  late final ApiClient _api;
  late final AuthService _authService;
  late final SocketService _socketService;

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isTyping = false.obs;
  final hasMore = true.obs;
  final onlineUsers = <String>{}.obs;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  String? _conversationId;
  String? _otherParticipantId;
  Timer? _typingTimer;
  StreamSubscription? _messageSub;
  StreamSubscription? _typingStartSub;
  StreamSubscription? _typingStopSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _offerUpdateSub;
  StreamSubscription? _readSub;
  StreamSubscription? _connectionSub;

  bool _initialLoadDone = false;
  bool _isFetchingMore = false;

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
    _offerUpdateSub?.cancel();
    _readSub?.cancel();
    _connectionSub?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Initialize with conversation data from arguments.
  void initConversation(String conversationId, String otherParticipantId) {
    _conversationId = conversationId;
    _otherParticipantId = otherParticipantId;
    _initialLoadDone = false;
    _isFetchingMore = false;
    hasMore.value = true;
    messages.clear(); // Clear old messages from previous conversation

    // Opening a thread means "no unread left" in the conversation list.
    try {
      Get.find<MessagesController>().markConversationReadLocally(conversationId);
    } catch (_) {}

    _socketService.joinConversation(conversationId);

    // Re-join if socket reconnects while this screen is open
    _connectionSub?.cancel();
    _connectionSub = _socketService.isConnected.listen((connected) {
      if (connected && _conversationId != null && !isClosed) {
        _socketService.joinConversation(_conversationId!);
      }
    });

    fetchMessages();
  }

  /// Fetch messages from API.
  Future<void> fetchMessages({bool loadMore = false}) async {
    if (_conversationId == null) return;
    if (isClosed) return;
    if (_isFetchingMore) return; // Prevent concurrent fetches

    if (loadMore) {
      _isFetchingMore = true;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
    }

    try {
      final query = <String, dynamic>{
        'limit': 20,
      };

      if (loadMore && messages.isNotEmpty) {
        // Messages are oldest-first, use FIRST message's timestamp as cursor (scroll up = older)
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
        final newMessages = response.data!;

        if (loadMore) {
          // Prepend older messages (avoid duplicates)
          final existingIds = messages.map((m) => m.id).toSet();
          final uniqueNew = newMessages.where((m) => !existingIds.contains(m.id)).toList();
          if (uniqueNew.isNotEmpty) {
            messages.insertAll(0, uniqueNew);
          }
          if (newMessages.length < 20) {
            hasMore.value = false;
          }
        } else {
          messages.assignAll(newMessages);
          _initialLoadDone = true;
          _scrollToBottom();
          // Server marks read on this GET — keep list badge in sync.
          if (_conversationId != null) {
            try {
              Get.find<MessagesController>()
                  .markConversationReadLocally(_conversationId!);
            } catch (_) {}
          }
        }

        if (response.meta != null) {
          hasMore.value = messages.length < response.meta!.total;
        }
      }
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error('Failed to load messages');
      }
    } finally {
      _isFetchingMore = false;
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
    final tempId = 'temp_${Random.secure().nextInt(999999999)}';
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
        AppFeedback.error('Failed to send message');
      }
    } catch (_) {
      if (!isClosed) {
        messages.removeWhere((m) => m.id == tempId);
        AppFeedback.error('Failed to send message');
      }
    }
  }

  /// Send an image message (REST only).
  Future<void> sendImageMessage(List<String> imageKeys) async {
    if (imageKeys.isEmpty || _conversationId == null) return;
    if (isClosed) return;

    final tempId = 'temp_${Random.secure().nextInt(999999999)}';
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

    final tempId = 'temp_${Random.secure().nextInt(999999999)}';
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
    String? date,
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
          if (date != null) 'date': date,
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
        AppFeedback.error('Failed to send offer');
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
        final resData = response.data;
        final checkoutUrl = resData?['checkoutUrl'] as String?;
        final paymentRequired = resData?['paymentRequired'] == true;

        if (paymentRequired && checkoutUrl != null && checkoutUrl.isNotEmpty) {
          final msg = messages.firstWhereOrNull((m) => m.id == offerMessageId);
          // Prefer server-computed hourly total when present
          final amountRaw = resData?['amount'];
          final offerPrice = amountRaw is num
              ? amountRaw.toDouble()
              : (msg?.offerData?.price ?? 0.0);
          final offerTitle = msg?.offerData?.title ?? 'Custom Service Offer';
          final sessId = resData?['sessionId'] as String? ?? '';

          _updateOfferStatus(offerMessageId, 'awaiting_payment');

          Get.toNamed(
            Routes.checkout,
            arguments: {
              'orderId': offerMessageId,
              'orderType': 'offer',
              'amount': offerPrice,
              'currency': 'MAD',
              'title': offerTitle,
              'sessionId': sessId,
              'metadata': {
                'userId': currentUserId,
                'helperId': msg?.senderId ?? _otherParticipantId ?? '',
                'offerMessageId': offerMessageId,
              },
            },
          )?.then((paid) {
            if (paid == true) {
              _updateOfferStatus(offerMessageId, 'accepted');
            }
          });
        } else {
          _updateOfferStatus(offerMessageId, 'accepted');
        }
      }
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error('Failed to accept offer');
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
        AppFeedback.error('Failed to reject offer');
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
        AppFeedback.error('Failed to cancel offer');
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
        AppFeedback.error('Failed to edit offer');
      }
    }
  }

  // ─── Private Helpers ─────────────────────────────────

  void _updateOfferStatus(String messageId, String status, {OfferData? offerData}) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final oldMsg = messages[idx];
    final existing = oldMsg.offerData;
    if (existing == null && offerData == null) return;

    final nextOffer = offerData ??
        OfferData(
          title: existing!.title,
          description: existing.description,
          price: existing.price,
          priceType: existing.priceType,
          date: existing.date,
          startTime: existing.startTime,
          endTime: existing.endTime,
          paymentMethod: existing.paymentMethod,
          images: existing.images,
          status: status,
        );

    messages[idx] = ChatMessage(
      id: oldMsg.id,
      conversationId: oldMsg.conversationId,
      senderId: oldMsg.senderId,
      type: oldMsg.type,
      content: oldMsg.content,
      images: oldMsg.images,
      video: oldMsg.video,
      offerData: nextOffer,
      createdAt: oldMsg.createdAt,
      isSentByMe: oldMsg.isSentByMe,
    );
  }

  /// Apply remote offer update (socket chat:offer-update).
  void _applyRemoteOfferUpdate(Map<String, dynamic> data) {
    final messageId = (data['messageId'] ?? data['offerId'] ?? '').toString();
    final conversationId = (data['conversationId'] ?? '').toString();
    if (messageId.isEmpty) return;
    if (conversationId.isNotEmpty && conversationId != _conversationId) return;

    OfferData? offerData;
    final offerMap = data['offerData'];
    if (offerMap is Map<String, dynamic>) {
      offerData = OfferData.fromJson(offerMap);
    }
    final status = offerData?.status ?? (data['status'] ?? '').toString();
    _updateOfferStatus(
      messageId,
      status.isNotEmpty ? status : 'pending',
      offerData: offerData,
    );
  }

  void _applyRemoteRead(Map<String, dynamic> data) {
    final userId = (data['userId'] ?? '').toString();
    if (userId.isEmpty || userId == currentUserId) return;
    final ids = (data['messageIds'] as List?)?.map((e) => e.toString()).toSet() ?? {};
    if (ids.isEmpty) return;
    for (var i = 0; i < messages.length; i++) {
      if (!ids.contains(messages[i].id)) continue;
      // ChatMessage is immutable — leave readBy display to model if present.
      // Presence of socket event is enough for UI "seen" when model supports it.
    }
  }

  void _setupStreamListeners() {
    // Listen for new messages via stream
    _messageSub = _socketService.onNewMessage.listen((message) {
      if (isClosed) return;
      if (message.conversationId == _conversationId) {
        // Skip own messages (sent via REST, will be added by REST response)
        if (message.senderId == currentUserId) return;
        // Skip duplicates (message already exists by ID)
        final exists = messages.any((m) => m.id == message.id);
        if (!exists) {
          messages.add(message);
          _scrollToBottom();
          // Thread is open — keep conversation list badge at 0.
          try {
            Get.find<MessagesController>()
                .markConversationReadLocally(message.conversationId);
          } catch (_) {}
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

    // Offer status / edit updates from peer
    _offerUpdateSub = _socketService.onOfferUpdate.listen((data) {
      if (isClosed) return;
      _applyRemoteOfferUpdate(data);
    });

    // Peer read receipts
    _readSub = _socketService.onMessagesRead.listen((data) {
      if (isClosed) return;
      _applyRemoteRead(data);
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
      // Load older messages when scrolling to TOP (oldest-first sort)
      if (!_initialLoadDone || _isFetchingMore || !hasMore.value) return;

      if (scrollController.position.pixels <= 50) {
        fetchMessages(loadMore: true);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
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
