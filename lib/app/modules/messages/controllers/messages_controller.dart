import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';

class ChatSummary {
  final String id;
  final String name;
  final String image;
  final String otherUserId;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isBlocked;

  ChatSummary({
    required this.id,
    required this.name,
    required this.image,
    this.otherUserId = '',
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
    this.isBlocked = false,
  });
}

class MessagesController extends GetxController {
  late final ApiClient _api;
  late final AuthService _authService;
  late final SocketService _socketService;

  final conversations = <ChatConversation>[].obs;

  /// True only for the very first load (drives the skeleton list).
  final isLoading = false.obs;
  final hasLoadedOnce = false.obs;
  final loadFailed = false.obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final onlineUserIds = <String>{}.obs;

  /// Conversation currently open on screen (its messages are read as they arrive).
  String? activeConversationId;

  /// Total unread messages — drives the badge on the Messages tab.
  int get totalUnread => conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

  StreamSubscription? _presenceSub;
  StreamSubscription? _newMessageSub;
  StreamSubscription? _conversationUpdatedSub;
  StreamSubscription? _syncSub;
  Worker? _loginWorker;
  bool _fetching = false;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiClient>();
    _authService = Get.find<AuthService>();
    _socketService = Get.find<SocketService>();
    _setupPresenceListener();
    _setupLiveListListener();
    // The controller is created before anyone is signed in: load the inbox as
    // soon as the user is (and again on every reconnection).
    _loginWorker = ever(_authService.isLoggedIn, (logged) {
      if (logged == true) {
        fetchConversations();
      } else {
        clear();
      }
    });
    _syncSub = _socketService.onSynced.listen((_) => fetchConversations());
    if (_authService.isLoggedIn.value) fetchConversations();
  }

  @override
  void onClose() {
    _presenceSub?.cancel();
    _newMessageSub?.cancel();
    _conversationUpdatedSub?.cancel();
    _syncSub?.cancel();
    _loginWorker?.dispose();
    super.onClose();
  }

  /// Clear all state on logout
  void clear() {
    conversations.clear();
    onlineUserIds.clear();
    searchQuery.value = '';
    isSearching.value = false;
    isLoading.value = false;
    hasLoadedOnce.value = false;
    loadFailed.value = false;
    activeConversationId = null;
  }

  void _setupPresenceListener() {
    _presenceSub = _socketService.onPresenceUpdate.listen((data) {
      final userId = data['userId']?.toString() ?? '';
      if (userId.isEmpty) return;
      if (data['isOnline'] == true) {
        onlineUserIds.add(userId);
      } else {
        onlineUserIds.remove(userId);
      }
    });
  }

  /// Keep conversation list / unread badges fresh when something arrives.
  void _setupLiveListListener() {
    // Messages for conversations this socket joined (the open chat).
    _newMessageSub = _socketService.onNewMessage.listen((message) {
      _applyIncoming(message);
    });
    // The server tells each user about new messages in conversations they have
    // NOT opened (and updates the list for the open one too).
    _conversationUpdatedSub = _socketService.onConversationUpdated.listen((data) {
      final raw = data['lastMessage'];
      if (raw is Map) {
        try {
          _applyIncoming(ChatMessage.fromJson(Map<String, dynamic>.from(raw)));
          return;
        } catch (_) {}
      }
      fetchConversations();
    });
  }

  void _applyIncoming(ChatMessage message) {
    if (isClosed) return;
    if (!_authService.isLoggedIn.value) return;
    final idx = conversations.indexWhere((c) => c.id == message.conversationId);
    if (idx == -1) {
      // New conversation for me — refresh list from API
      fetchConversations();
      return;
    }
    final conv = conversations[idx];
    // Same message seen twice (room event + user event): ignore the second.
    if (conv.lastMessage?.id == message.id) return;
    final isMine = message.senderId == currentUserId;
    final isOpen = activeConversationId == message.conversationId;
    final updated = conv.copyWith(
      lastMessage: message,
      lastMessageAt: message.createdAt,
      unreadCount: (isMine || isOpen) ? conv.unreadCount : conv.unreadCount + 1,
    );
    conversations.removeAt(idx);
    conversations.insert(0, updated);
  }

  /// Zero local unread after the user opens a thread (server already marked read).
  void markConversationReadLocally(String conversationId) {
    if (conversationId.isEmpty) return;
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final conv = conversations[idx];
    if (conv.unreadCount == 0) return;
    conversations[idx] = conv.copyWith(unreadCount: 0);
  }

  void setBlockedLocally(String conversationId, bool blocked) {
    final idx = conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    conversations[idx] = conversations[idx].copyWith(isBlocked: blocked);
  }

  List<ChatSummary> get filteredChats {
    final query = searchQuery.value.toLowerCase();
    return conversations
        // A conversation nobody wrote in yet is not worth a row.
        .where((conv) => conv.lastMessage != null)
        .map((conv) {
          final other = conv.otherParticipant;
          final otherId = other?.id ?? '';
          final avatar = other?.avatar ?? '';
          return ChatSummary(
            id: conv.id,
            name: (other?.name.isNotEmpty ?? false) ? other!.name : 'ui_unknown'.tr,
            image: ApiConstants.resolveImageUrl(avatar) ?? avatar,
            otherUserId: otherId,
            lastMessage: conv.lastMessage?.preview ?? '',
            time: _formatTime(conv.lastMessageAt),
            unreadCount: conv.unreadCount,
            isOnline: conv.isOnline || onlineUserIds.contains(otherId),
            isBlocked: conv.isBlocked,
          );
        })
        .where((chat) {
          if (query.isEmpty) return true;
          return chat.name.toLowerCase().contains(query);
        })
        .toList();
  }

  /// Fetch all conversations from API. Never shows the full-screen loader again
  /// once something has been loaded: the list updates in place.
  Future<void> fetchConversations() async {
    if (!_authService.isLoggedIn.value) return;
    if (_fetching) return;
    _fetching = true;
    if (!hasLoadedOnce.value) isLoading.value = true;
    try {
      final response = await _api.get<List<ChatConversation>>(
        ApiConstants.chatConversations,
        fromData: (data) {
          if (data is List) {
            return data
                .whereType<Map>()
                .map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
          return <ChatConversation>[];
        },
      );

      if (response.success && response.data != null && !isClosed) {
        final fresh = response.data!;
        // The conversation being read stays at zero even if the list was loaded a moment earlier.
        final open = activeConversationId;
        final fixed = open == null
            ? fresh
            : fresh.map((c) => c.id == open ? c.copyWith(unreadCount: 0) : c).toList();
        conversations.assignAll(fixed);
        for (final c in fixed) {
          final id = c.otherParticipant?.id ?? '';
          if (id.isEmpty) continue;
          if (c.isOnline) {
            onlineUserIds.add(id);
          } else {
            onlineUserIds.remove(id);
          }
        }
        loadFailed.value = false;
        hasLoadedOnce.value = true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Messages] fetch failed: $e');
      if (!hasLoadedOnce.value && !isClosed) loadFailed.value = true;
    } finally {
      _fetching = false;
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Refresh conversations (pull-to-refresh).
  Future<void> refreshData() async {
    await fetchConversations();
  }

  /// Start or get existing conversation with a user/helper.
  /// Shows the reason (not allowed, user unavailable, …) instead of failing silently.
  Future<ChatConversation?> startConversation(String participantId) async {
    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatConversations,
        data: {'participantId': participantId},
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final conversation = ChatConversation.fromJson(Map<String, dynamic>.from(data));
          unawaited(fetchConversations());
          return conversation;
        }
      }
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
    return null;
  }

  /// Get the current user ID.
  String? get currentUserId => _authService.currentUser.value?.id;

  /// Resolve a ChatSummary for deep-links (push tap) by conversation id.
  /// Uses cache first, then refetches the conversation list.
  Future<ChatSummary?> resolveChatSummary(String conversationId) async {
    if (conversationId.isEmpty) return null;

    ChatSummary? fromList() {
      for (final conv in conversations) {
        if (conv.id != conversationId) continue;
        final other = conv.otherParticipant;
        final avatar = other?.avatar ?? '';
        return ChatSummary(
          id: conv.id,
          name: (other?.name.isNotEmpty ?? false) ? other!.name : 'btn_chat'.tr,
          image: ApiConstants.resolveImageUrl(avatar) ?? avatar,
          otherUserId: other?.id ?? '',
          unreadCount: conv.unreadCount,
          isOnline: conv.isOnline,
          isBlocked: conv.isBlocked,
        );
      }
      return null;
    }

    var summary = fromList();
    if (summary != null) return summary;

    await fetchConversations();
    summary = fromList();
    if (summary != null) return summary;

    // Fallback: minimal summary so the chat screen can open and load messages.
    return ChatSummary(id: conversationId, name: 'btn_chat'.tr, image: '');
  }

  /// Format time for display (localized).
  String _formatTime(DateTime dateTime) => AppDateTime.shortAgo(dateTime);
}
