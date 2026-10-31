import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/video_compressor.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class ChatDetailController extends GetxController {
  late final ApiClient _api;
  late final AuthService _authService;
  late final SocketService _socketService;

  final messages = <ChatMessage>[].obs;

  /// First load only (drives the skeleton).
  final isLoading = false.obs;
  final loadFailed = false.obs;
  final isLoadingMore = false.obs;
  final isTyping = false.obs;
  final hasMore = true.obs;
  final onlineUsers = <String>{}.obs;
  final isBlocked = false.obs;

  /// Messages that arrived while the user is reading older ones ("new messages ↓" pill).
  final newBelowCount = 0.obs;
  final isNearBottom = true.obs;

  /// Upload progress (0..1) of local media messages, by temp id.
  final uploadProgress = <String, double>{}.obs;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  String? _conversationId;
  String? _otherParticipantId;
  String? _nextBefore;
  Timer? _typingTimer;
  Timer? _remoteTypingExpiry;
  DateTime? _lastTypingSent;
  StreamSubscription? _messageSub;
  StreamSubscription? _typingStartSub;
  StreamSubscription? _typingStopSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _offerUpdateSub;
  StreamSubscription? _readSub;
  StreamSubscription? _syncSub;
  StreamSubscription? _chatErrorSub;

  bool _initialLoadDone = false;
  bool _isFetchingMore = false;
  bool _fetchingLatest = false;

  /// The conversation on screen (null before [initConversation]).
  String? get conversationId => _conversationId;
  String? get otherParticipantId => _otherParticipantId;

  String? get currentUserId => _authService.currentUser.value?.id;

  bool get isOtherOnline => _otherParticipantId != null && onlineUsers.contains(_otherParticipantId);

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
    final id = _conversationId;
    if (id != null) {
      _socketService.leaveConversation(id);
      if (Get.isRegistered<MessagesController>()) {
        final mc = Get.find<MessagesController>();
        if (mc.activeConversationId == id) mc.activeConversationId = null;
      }
    }
    _typingTimer?.cancel();
    _remoteTypingExpiry?.cancel();
    _messageSub?.cancel();
    _typingStartSub?.cancel();
    _typingStopSub?.cancel();
    _presenceSub?.cancel();
    _offerUpdateSub?.cancel();
    _readSub?.cancel();
    _syncSub?.cancel();
    _chatErrorSub?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Initialize with conversation data from arguments.
  void initConversation(String conversationId, String otherParticipantId) {
    if (_conversationId != null && _conversationId != conversationId) {
      _socketService.leaveConversation(_conversationId!);
    }
    _conversationId = conversationId;
    _otherParticipantId = otherParticipantId.isEmpty ? null : otherParticipantId;
    _initialLoadDone = false;
    _isFetchingMore = false;
    _nextBefore = null;
    hasMore.value = true;
    loadFailed.value = false;
    newBelowCount.value = 0;
    messages.clear(); // Clear old messages from previous conversation

    if (Get.isRegistered<MessagesController>()) {
      final mc = Get.find<MessagesController>();
      mc.activeConversationId = conversationId;
      // Opening a thread means "no unread left" in the conversation list.
      mc.markConversationReadLocally(conversationId);
      final conv = mc.conversations.firstWhereOrNull((c) => c.id == conversationId);
      if (conv != null) {
        isBlocked.value = conv.isBlocked;
        final other = conv.otherParticipant?.id ?? '';
        if (other.isNotEmpty) {
          _otherParticipantId ??= other;
          if (conv.isOnline) onlineUsers.add(other);
        }
      }
    }

    _socketService.joinConversation(conversationId);

    // After every reconnection: re-join happens inside the socket service,
    // here we fetch whatever was said while we were offline.
    _syncSub?.cancel();
    _syncSub = _socketService.onSynced.listen((_) {
      if (!isClosed && _initialLoadDone) fetchLatest();
    });

    fetchMessages();
    _loadPresence();
  }

  // ─── Loading ─────────────────────────────────────────

  /// First page (or "load older" when [loadMore]).
  Future<void> fetchMessages({bool loadMore = false}) async {
    if (_conversationId == null) return;
    if (isClosed) return;
    if (_isFetchingMore) return; // Prevent concurrent fetches

    if (loadMore) {
      if (_nextBefore == null) return;
      _isFetchingMore = true;
      isLoadingMore.value = true;
    } else {
      isLoading.value = messages.isEmpty;
      loadFailed.value = false;
    }

    try {
      final query = <String, dynamic>{'limit': 20};
      if (loadMore && _nextBefore != null) {
        query['before'] = _nextBefore;
      }

      final response = await _api.get<dynamic>(
        ApiConstants.chatMessages(_conversationId!),
        queryParameters: query,
        fromData: (d) => d,
      );

      if (isClosed) return;

      final data = response.data;
      if (response.success && data is Map) {
        final docs = (data['docs'] as List? ?? [])
            .whereType<Map>()
            .map((e) => _fromServer(Map<String, dynamic>.from(e)))
            .toList();
        _nextBefore = data['nextBefore']?.toString();
        hasMore.value = data['hasMore'] == true;

        if (loadMore) {
          // Prepend older messages (avoid duplicates), keeping the scroll position
          final existingIds = messages.map((m) => m.id).toSet();
          final uniqueNew = docs.where((m) => !existingIds.contains(m.id)).toList();
          if (uniqueNew.isNotEmpty) {
            final before = scrollController.hasClients ? scrollController.position.extentAfter : 0.0;
            messages.insertAll(0, uniqueNew);
            _keepScrollPosition(before);
          }
        } else {
          _mergeLatest(docs);
          _initialLoadDone = true;
          _scrollToBottom(force: true);
          // Server marks read on this GET — keep list badge in sync.
          if (Get.isRegistered<MessagesController>()) {
            Get.find<MessagesController>().markConversationReadLocally(_conversationId!);
          }
        }
      }
    } catch (e) {
      if (!isClosed) {
        if (!loadMore && messages.isEmpty) {
          loadFailed.value = true;
        } else {
          AppFeedback.error(AppSnackbar.extractErrorMessage(e));
        }
      }
    } finally {
      _isFetchingMore = false;
      if (!isClosed) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  /// Fetch the newest page and merge it in (after a reconnection / app resume).
  Future<void> fetchLatest() async {
    if (_conversationId == null || _fetchingLatest || isClosed) return;
    _fetchingLatest = true;
    try {
      final response = await _api.get<dynamic>(
        ApiConstants.chatMessages(_conversationId!),
        queryParameters: {'limit': 20},
        fromData: (d) => d,
      );
      final data = response.data;
      if (!isClosed && response.success && data is Map) {
        final docs = (data['docs'] as List? ?? [])
            .whereType<Map>()
            .map((e) => _fromServer(Map<String, dynamic>.from(e)))
            .toList();
        final wasNearBottom = isNearBottom.value;
        _mergeLatest(docs);
        if (wasNearBottom) _scrollToBottom();
      }
    } catch (_) {
      // best effort: the socket keeps delivering new messages
    } finally {
      _fetchingLatest = false;
    }
  }

  ChatMessage _fromServer(Map<String, dynamic> json) {
    final msg = ChatMessage.fromJson(json);
    return msg.copyWith(isSentByMe: msg.senderId == currentUserId);
  }

  /// Replace server-known messages with the fresh copies, add the new ones and
  /// keep the local (sending / failed) ones at the end.
  void _mergeLatest(List<ChatMessage> fresh) {
    final locals = messages.where((m) => m.isLocal).toList();
    final byId = {for (final m in messages.where((m) => !m.isLocal)) m.id: m};
    for (final m in fresh) {
      byId[m.id] = m;
    }
    final merged = byId.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    messages.assignAll([...merged, ...locals]);
  }

  /// Presence from the API (the live events only tell what changes afterwards).
  Future<void> _loadPresence() async {
    final other = _otherParticipantId;
    if (other == null) return;
    try {
      final response = await _api.get<dynamic>(
        ApiConstants.chatPresence,
        queryParameters: {'ids': other},
        fromData: (d) => d,
      );
      final data = response.data;
      if (!isClosed && data is Map) {
        if (data[other] == true) {
          onlineUsers.add(other);
        } else {
          onlineUsers.remove(other);
        }
      }
    } catch (_) {}
  }

  // ─── Sending ─────────────────────────────────────────

  String _tempId() => 'temp_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  /// Send what is in the text box. The bubble appears at once; if sending fails
  /// it stays with a "tap to retry" action — nothing is ever lost silently.
  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _conversationId == null || isClosed) return;
    if (isBlocked.value) {
      AppFeedback.error('err_conversation_blocked'.tr);
      return;
    }

    messageController.clear();
    _stopTyping();

    final local = ChatMessage(
      id: _tempId(),
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'text',
      content: text,
      createdAt: DateTime.now(),
      isSentByMe: true,
      delivery: MessageDelivery.sending,
    );
    messages.add(local);
    _scrollToBottom(force: true);
    await _deliver(local);
  }

  /// Photos picked by the user: shown immediately from the device, uploaded, then sent.
  Future<void> sendImageFiles(List<String> paths) async {
    if (paths.isEmpty || _conversationId == null || isClosed) return;
    final local = ChatMessage(
      id: _tempId(),
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'image',
      createdAt: DateTime.now(),
      isSentByMe: true,
      delivery: MessageDelivery.sending,
    ).withLocalFiles(paths.take(4).toList());
    messages.add(local);
    _scrollToBottom(force: true);
    await _deliver(local);
  }

  /// A video picked by the user: compressed, uploaded, then sent.
  Future<void> sendVideoFile(String path) async {
    if (_conversationId == null || isClosed) return;
    final local = ChatMessage(
      id: _tempId(),
      conversationId: _conversationId!,
      senderId: currentUserId ?? '',
      type: 'video',
      createdAt: DateTime.now(),
      isSentByMe: true,
      delivery: MessageDelivery.sending,
    ).withLocalFiles([path]);
    messages.add(local);
    _scrollToBottom(force: true);
    await _deliver(local);
  }

  /// Uploads (if needed) and posts one local message; updates it in the list.
  Future<void> _deliver(ChatMessage local) async {
    final convId = _conversationId;
    if (convId == null) return;
    _replace(local.id, (m) => m.copyWith(delivery: MessageDelivery.sending, clearError: true));

    try {
      final body = <String, dynamic>{'type': local.type};
      if (local.type == 'text') {
        body['content'] = local.content;
      } else if (local.type == 'image') {
        final keys = <String>[];
        var done = 0;
        for (final path in local.localFiles) {
          keys.add(await _upload(ApiConstants.uploadImage, path));
          done++;
          uploadProgress[local.id] = done / local.localFiles.length;
        }
        body['images'] = keys;
      } else if (local.type == 'video') {
        File? compressed;
        try {
          compressed = await VideoCompressor.compress(local.localFiles.first);
        } catch (_) {}
        final file = compressed ?? File(local.localFiles.first);
        if (await file.length() > 400 * 1024 * 1024) {
          throw ApiException('ui_video_must_be_under_400mb'.tr);
        }
        try {
          body['video'] = await _upload(
            ApiConstants.uploadVideo,
            file.path,
            onProgress: (p) => uploadProgress[local.id] = p,
          );
        } finally {
          if (compressed != null) {
            try {
              await compressed.delete();
            } catch (_) {}
          }
        }
      }

      final response = await _api.post<dynamic>(ApiConstants.chatMessages(convId), data: body);
      if (isClosed) return;
      final data = response.data;
      if (response.success && data is Map) {
        final real = _fromServer(Map<String, dynamic>.from(data)).copyWith(isSentByMe: true);
        final idx = messages.indexWhere((m) => m.id == local.id);
        final alreadyThere = messages.any((m) => m.id == real.id);
        if (alreadyThere) {
          // The socket delivered it first: just drop the local copy.
          messages.removeWhere((m) => m.id == local.id);
        } else if (idx != -1) {
          messages[idx] = real;
        }
        uploadProgress.remove(local.id);
        _noteSentInList(real);
      } else {
        throw ApiException(response.message ?? 'ui_failed_to_send_message'.tr);
      }
    } catch (e) {
      if (isClosed) return;
      uploadProgress.remove(local.id);
      final reason = AppSnackbar.extractErrorMessage(e);
      _replace(
        local.id,
        (m) => m.copyWith(delivery: MessageDelivery.failed, errorText: reason),
      );
      // A blocked conversation: remember it so the input stays disabled.
      if (e is ApiException && e.code == 'CONVERSATION_BLOCKED') isBlocked.value = true;
    }
  }

  Future<String> _upload(String endpoint, String path, {void Function(double)? onProgress}) async {
    final formData = dio.FormData.fromMap({
      'file': await dio.MultipartFile.fromFile(path, filename: path.split(Platform.pathSeparator).last),
    });
    final response = await _api.upload<dynamic>(
      endpoint,
      formData: formData,
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) onProgress(sent / total);
            },
    );
    final data = response.data;
    final key = data is Map ? (data['key'] ?? data['url'])?.toString() : null;
    if (response.success && key != null && key.isNotEmpty) return key;
    throw ApiException(response.message ?? 'ui_failed_to_upload_images'.tr);
  }

  /// Tap "retry" on a failed bubble.
  Future<void> retryMessage(String tempId) async {
    final msg = messages.firstWhereOrNull((m) => m.id == tempId);
    if (msg == null || msg.delivery == MessageDelivery.sending) return;
    await _deliver(msg);
  }

  /// Remove a failed bubble. Its text goes back to the input so it can be edited.
  void discardMessage(String tempId, {bool restoreText = false}) {
    final msg = messages.firstWhereOrNull((m) => m.id == tempId);
    if (msg == null) return;
    messages.removeWhere((m) => m.id == tempId);
    uploadProgress.remove(tempId);
    if (restoreText && msg.type == 'text' && messageController.text.isEmpty) {
      messageController.text = msg.content ?? '';
    }
  }

  void _noteSentInList(ChatMessage real) {
    if (!Get.isRegistered<MessagesController>()) return;
    final mc = Get.find<MessagesController>();
    final idx = mc.conversations.indexWhere((c) => c.id == real.conversationId);
    if (idx == -1) return;
    final conv = mc.conversations[idx].copyWith(lastMessage: real, lastMessageAt: real.createdAt);
    mc.conversations.removeAt(idx);
    mc.conversations.insert(0, conv);
  }

  void _replace(String id, ChatMessage Function(ChatMessage) change) {
    final idx = messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    messages[idx] = change(messages[idx]);
  }

  // ─── Offers ──────────────────────────────────────────

  /// Send a service offer. Returns true on success (the form stays open otherwise).
  Future<bool> sendOffer({
    required String title,
    String? description,
    required double price,
    String priceType = 'fixed',
    String? date,
    String? startTime,
    String? endTime,
    String? address,
    double? latitude,
    double? longitude,
    String paymentMethod = 'cash',
    List<String>? images,
  }) async {
    if (_conversationId == null || isClosed) return false;
    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatOffer(_conversationId!),
        data: {
          'title': title,
          if (description != null && description.isNotEmpty) 'description': description,
          'price': price,
          'priceType': priceType,
          if (date != null) 'date': date,
          if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
          if (endTime != null && endTime.isNotEmpty) 'endTime': endTime,
          if (address != null && address.isNotEmpty) 'address': address,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'paymentMethod': paymentMethod,
          if (images != null && images.isNotEmpty) 'images': images,
        },
      );

      if (isClosed) return false;
      final data = response.data;
      if (response.success && data is Map) {
        final msg = _fromServer(Map<String, dynamic>.from(data)).copyWith(isSentByMe: true);
        if (!messages.any((m) => m.id == msg.id)) messages.add(msg);
        _noteSentInList(msg);
        _scrollToBottom(force: true);
        return true;
      }
      return false;
    } catch (e) {
      if (!isClosed) AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  /// Accept an offer. The client accepts the exact version they were looking at.
  Future<void> acceptOffer(String offerMessageId) async {
    if (_conversationId == null || isClosed) return;
    final msg = messages.firstWhereOrNull((m) => m.id == offerMessageId);
    final version = msg?.offerData?.version ?? 1;

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferAccept(_conversationId!, offerMessageId),
        data: {'version': version},
      );

      if (isClosed) return;

      if (response.success) {
        final resData = response.data;
        final checkoutUrl = resData?['checkoutUrl'] as String?;
        final paymentRequired = resData?['paymentRequired'] == true;

        if (paymentRequired && checkoutUrl != null && checkoutUrl.isNotEmpty) {
          // Prefer server-computed total
          final amountRaw = resData?['amount'];
          final offerPrice = amountRaw is num
              ? amountRaw.toDouble()
              : (msg?.offerData?.total ?? 0.0);
          final offerTitle = msg?.offerData?.title ?? 'ui_custom_service_offer'.tr;
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
          AppFeedback.success('chat_offer_accepted_msg'.tr, title: 'chat_offer_accepted_title'.tr);
          if (Get.isRegistered<MessagesController>()) {
            // The new job shows in Bookings.
            unawaited(Get.find<MessagesController>().fetchConversations());
          }
        }
      }
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error(AppSnackbar.extractErrorMessage(e));
        // The offer may have changed under us: show the current version.
        unawaited(fetchLatest());
      }
    }
  }

  /// Reject an offer.
  Future<void> rejectOffer(String offerMessageId) async {
    if (_conversationId == null || isClosed) return;
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferReject(_conversationId!, offerMessageId),
      );
      if (isClosed) return;
      if (response.success) _updateOfferStatus(offerMessageId, 'rejected');
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error(AppSnackbar.extractErrorMessage(e));
        unawaited(fetchLatest());
      }
    }
  }

  /// Cancel/withdraw an offer (helper only).
  Future<void> cancelOffer(String offerMessageId) async {
    if (_conversationId == null || isClosed) return;
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.chatOfferCancel(_conversationId!, offerMessageId),
      );
      if (isClosed) return;
      if (response.success) _updateOfferStatus(offerMessageId, 'cancelled');
    } catch (e) {
      if (!isClosed) {
        AppFeedback.error(AppSnackbar.extractErrorMessage(e));
        unawaited(fetchLatest());
      }
    }
  }

  /// Edit an offer (helper only, before acceptance). Returns true on success.
  Future<bool> editOffer(
    String offerMessageId, {
    String? title,
    String? description,
    double? price,
    String? priceType,
    String? date,
    String? startTime,
    String? endTime,
    String? address,
    double? latitude,
    double? longitude,
    String? paymentMethod,
    List<String>? images,
  }) async {
    if (_conversationId == null || isClosed) return false;

    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (priceType != null) data['priceType'] = priceType;
      if (date != null) data['date'] = date;
      if (startTime != null) data['startTime'] = startTime;
      if (endTime != null) data['endTime'] = endTime;
      if (address != null && address.isNotEmpty) data['address'] = address;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (paymentMethod != null) data['paymentMethod'] = paymentMethod;
      if (images != null) data['images'] = images;

      final response = await _api.patch<Map<String, dynamic>>(
        ApiConstants.chatOfferEdit(_conversationId!, offerMessageId),
        data: data,
      );

      if (isClosed) return false;

      if (response.success && response.data != null) {
        final idx = messages.indexWhere((m) => m.id == offerMessageId);
        if (idx != -1) {
          messages[idx] = _fromServer(response.data!).copyWith(isSentByMe: true);
        }
        return true;
      }
      return false;
    } catch (e) {
      if (!isClosed) AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  // ─── Block / report ──────────────────────────────────

  Future<void> setBlocked(bool blocked) async {
    final id = _conversationId;
    if (id == null) return;
    try {
      await _api.post<dynamic>(blocked ? ApiConstants.chatBlock(id) : ApiConstants.chatUnblock(id));
      if (isClosed) return;
      isBlocked.value = blocked;
      if (Get.isRegistered<MessagesController>()) {
        Get.find<MessagesController>().setBlockedLocally(id, blocked);
      }
      AppFeedback.success(blocked ? 'chat_blocked_msg'.tr : 'chat_unblocked_msg'.tr);
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
  }

  Future<void> reportConversation(String reason, {String? message}) async {
    final id = _conversationId;
    if (id == null) return;
    try {
      await _api.post<dynamic>(
        ApiConstants.chatReport(id),
        data: {
          'reason': reason,
          if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
        },
      );
      AppFeedback.success('chat_report_sent'.tr);
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
  }

  // ─── Private Helpers ─────────────────────────────────

  void _updateOfferStatus(String messageId, String status, {OfferData? offerData}) {
    final idx = messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final old = messages[idx];
    final next = offerData ?? old.offerData?.copyWith(status: status);
    if (next == null) return;
    messages[idx] = old.copyWith(offerData: next);
  }

  /// Apply remote offer update (socket chat:offer-update).
  void _applyRemoteOfferUpdate(Map<String, dynamic> data) {
    final messageId = (data['messageId'] ?? data['offerId'] ?? '').toString();
    final conversationId = (data['conversationId'] ?? '').toString();
    if (messageId.isEmpty) return;
    if (conversationId.isNotEmpty && conversationId != _conversationId) return;

    OfferData? offerData;
    final offerMap = data['offerData'];
    if (offerMap is Map) {
      offerData = OfferData.fromJson(Map<String, dynamic>.from(offerMap));
    }
    final status = offerData?.status ?? (data['status'] ?? '').toString();
    _updateOfferStatus(
      messageId,
      status.isNotEmpty ? status : 'pending',
      offerData: offerData,
    );
  }

  /// The other person read some of my messages: mark them (✓✓).
  void _applyRemoteRead(Map<String, dynamic> data) {
    final userId = (data['userId'] ?? '').toString();
    if (userId.isEmpty || userId == currentUserId) return;
    final convId = (data['conversationId'] ?? '').toString();
    if (convId.isNotEmpty && convId != _conversationId) return;
    final ids = (data['messageIds'] as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
    if (ids.isEmpty) return;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (!ids.contains(m.id) || m.readBy.contains(userId)) continue;
      messages[i] = m.copyWith(readBy: [...m.readBy, userId]);
    }
  }

  void _setupStreamListeners() {
    // Listen for new messages via stream
    _messageSub = _socketService.onNewMessage.listen((message) {
      if (isClosed) return;
      if (message.conversationId != _conversationId) return;
      // Skip own messages (sent via REST, will be added by REST response)
      if (message.senderId == currentUserId) return;
      // Skip duplicates (message already exists by ID)
      if (messages.any((m) => m.id == message.id)) return;

      messages.add(message);
      isTyping.value = false;
      if (isNearBottom.value) {
        _scrollToBottom();
      } else {
        newBelowCount.value++;
      }
      // The thread is open: tell the sender it was read and keep the badge at 0.
      _socketService.markRead(message.conversationId, [message.id]);
      if (Get.isRegistered<MessagesController>()) {
        Get.find<MessagesController>().markConversationReadLocally(message.conversationId);
      }
    });

    // Listen for typing start — expires by itself if "stop" is lost
    _typingStartSub = _socketService.onTypingStart.listen((data) {
      if (isClosed) return;
      if (data['conversationId'] == _conversationId && data['userId'] != currentUserId) {
        isTyping.value = true;
        _remoteTypingExpiry?.cancel();
        _remoteTypingExpiry = Timer(const Duration(seconds: 5), () {
          if (!isClosed) isTyping.value = false;
        });
      }
    });

    // Listen for typing stop
    _typingStopSub = _socketService.onTypingStop.listen((data) {
      if (isClosed) return;
      if (data['conversationId'] == _conversationId && data['userId'] != currentUserId) {
        isTyping.value = false;
        _remoteTypingExpiry?.cancel();
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
      final userId = data['userId']?.toString() ?? '';
      if (userId.isEmpty) return;
      if (data['isOnline'] == true) {
        onlineUsers.add(userId);
      } else {
        onlineUsers.remove(userId);
      }
    });

    // Server refused a socket message (rate limit, blocked, …)
    _chatErrorSub = _socketService.onChatError.listen((data) {
      if (isClosed) return;
      final convId = data['conversationId']?.toString();
      if (convId != null && convId != _conversationId) return;
      final code = data['code']?.toString();
      if (code == 'CONVERSATION_BLOCKED') isBlocked.value = true;
      final key = 'err_${(code ?? '').toLowerCase()}';
      AppFeedback.error(key.tr != key ? key.tr : (data['message']?.toString() ?? 'err_http_unknown'.tr));
    });
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      final near = pos.extentAfter < 120;
      if (near != isNearBottom.value) {
        isNearBottom.value = near;
        if (near) newBelowCount.value = 0;
      }

      // Load older messages when scrolling to TOP (oldest-first sort)
      if (!_initialLoadDone || _isFetchingMore || !hasMore.value) return;
      if (pos.pixels <= 50) {
        fetchMessages(loadMore: true);
      }
    });
  }

  /// Scroll to the newest message. Without [force] only when the user is already
  /// at the bottom — never yank someone who is reading older messages.
  void _scrollToBottom({bool force = false}) {
    if (!force && !isNearBottom.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      isNearBottom.value = true;
      newBelowCount.value = 0;
    });
  }

  /// "New messages ↓" pill tapped.
  void scrollToLatest() => _scrollToBottom(force: true);

  /// After inserting older messages on top, keep the same message under the finger.
  void _keepScrollPosition(double extentAfterBefore) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final target = scrollController.position.maxScrollExtent - extentAfterBefore;
      if (target > 0) scrollController.jumpTo(target);
    });
  }

  void _startTyping() {
    if (_conversationId == null) return;
    final now = DateTime.now();
    // At most one "typing" event every 2 seconds, not one per keystroke.
    if (_lastTypingSent == null || now.difference(_lastTypingSent!) > const Duration(seconds: 2)) {
      _lastTypingSent = now;
      _socketService.startTyping(_conversationId!);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    if (_conversationId == null) return;
    if (_lastTypingSent != null) {
      _socketService.stopTyping(_conversationId!);
      _lastTypingSent = null;
    }
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
