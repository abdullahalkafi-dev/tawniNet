import 'dart:async';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
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

  ChatSummary({
    required this.id,
    required this.name,
    required this.image,
    this.otherUserId = '',
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class MessagesController extends GetxController {
  late final ApiClient _api;
  late final AuthService _authService;
  late final SocketService _socketService;

  final conversations = <ChatConversation>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;
  final onlineUserIds = <String>{}.obs;

  StreamSubscription? _presenceSub;
  StreamSubscription? _newMessageSub;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiClient>();
    _authService = Get.find<AuthService>();
    _socketService = Get.find<SocketService>();
    _setupPresenceListener();
    _setupLiveListListener();
    fetchConversations();
  }

  @override
  void onClose() {
    _presenceSub?.cancel();
    _newMessageSub?.cancel();
    super.onClose();
  }

  /// Clear all state on logout
  void clear() {
    conversations.clear();
    onlineUserIds.clear();
    searchQuery.value = '';
    isSearching.value = false;
    isLoading.value = false;
  }

  void _setupPresenceListener() {
    _presenceSub = _socketService.onPresenceUpdate.listen((data) {
      final userId = data['userId'] as String? ?? '';
      final isOnline = data['isOnline'] as bool? ?? false;
      if (isOnline) {
        onlineUserIds.add(userId);
      } else {
        onlineUserIds.remove(userId);
      }
    });
  }

  /// Keep conversation list / unread badges fresh when a message arrives.
  void _setupLiveListListener() {
    _newMessageSub = _socketService.onNewMessage.listen((message) {
      if (isClosed) return;
      if (!_authService.isLoggedIn.value) return;
      final idx = conversations.indexWhere((c) => c.id == message.conversationId);
      if (idx == -1) {
        // New conversation for me — refresh list from API
        fetchConversations();
        return;
      }
      final conv = conversations[idx];
      final isMine = message.senderId == currentUserId;
      final updated = conv.copyWith(
        lastMessage: message,
        lastMessageAt: message.createdAt,
        unreadCount: isMine ? conv.unreadCount : conv.unreadCount + 1,
      );
      conversations.removeAt(idx);
      conversations.insert(0, updated);
    });
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

  List<ChatSummary> get filteredChats {
    final query = searchQuery.value.toLowerCase();
    return conversations.map((conv) {
      final other = conv.otherParticipant;
      final otherId = other?.id ?? '';
      final avatar = other?.avatar ?? '';
      return ChatSummary(
        id: conv.id,
        name: other?.name ?? 'Unknown',
        image: ApiConstants.resolveImageUrl(avatar) ?? avatar,
        otherUserId: otherId,
        lastMessage: conv.lastMessage?.content ??
            (conv.lastMessage?.type == 'image' ? '📷 Image' : ''),
        time: _formatTime(conv.lastMessageAt),
        unreadCount: conv.unreadCount,
        isOnline: onlineUserIds.contains(otherId),
      );
    }).where((chat) {
      if (query.isEmpty) return true;
      return chat.name.toLowerCase().contains(query);
    }).toList();
  }

  /// Fetch all conversations from API.
  Future<void> fetchConversations() async {
    if (!_authService.isLoggedIn.value) {
      return;
    }
    isLoading.value = true;
    try {
      final response = await _api.get<List<ChatConversation>>(
        ApiConstants.chatConversations,
        fromData: (data) {
          if (data is List) {
            return data
                .map((e) => ChatConversation.fromJson(e))
                .toList();
          }
          return <ChatConversation>[];
        },
      );

      if (response.success && response.data != null) {
        if (!isClosed) {
          conversations.assignAll(response.data!);
        }
      }
    } catch (e) {
      // Silent fail
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Refresh conversations (pull-to-refresh).
  Future<void> refreshData() async {
    await fetchConversations();
  }

  /// Start or get existing conversation with a user/helper.
  Future<ChatConversation?> startConversation(String participantId) async {
    try {
      final response = await _api.post<dynamic>(
        ApiConstants.chatConversations,
        data: {'participantId': participantId},
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final conversation = ChatConversation.fromJson(data);
          await fetchConversations();
          return conversation;
        }
      }
    } catch (e) {
      // Silent fail
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
      for (final chat in filteredChats) {
        if (chat.id == conversationId) return chat;
      }
      return null;
    }

    var summary = fromList();
    if (summary != null) return summary;

    await fetchConversations();
    summary = fromList();
    if (summary != null) return summary;

    // Fallback: minimal summary so the chat screen can open and load messages.
    return ChatSummary(id: conversationId, name: 'Chat', image: '');
  }

  /// Format time for display.
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
