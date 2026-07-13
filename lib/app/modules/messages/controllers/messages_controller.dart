import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';

class ChatSummary {
  final String id;
  final String name;
  final String image;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;

  ChatSummary({
    required this.id,
    required this.name,
    required this.image,
    this.lastMessage = '',
    this.time = '',
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class MessagesController extends GetxController {
  final _api = Get.find<ApiClient>();
  final _authService = Get.find<AuthService>();

  final conversations = <ChatConversation>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final isSearching = false.obs;

  List<ChatSummary> get filteredChats {
    final query = searchQuery.value.toLowerCase();
    return conversations.map((conv) {
      final other = conv.otherParticipant;
      return ChatSummary(
        id: conv.id,
        name: other?.name ?? 'Unknown',
        image: other?.avatar ?? '',
        lastMessage: conv.lastMessage?.content ??
            (conv.lastMessage?.type == 'image' ? '📷 Image' : ''),
        time: _formatTime(conv.lastMessageAt),
        unreadCount: conv.unreadCount,
      );
    }).where((chat) {
      if (query.isEmpty) return true;
      return chat.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
  }

  /// Fetch all conversations from API.
  Future<void> fetchConversations() async {
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
        conversations.assignAll(response.data!);
      }
    } catch (e) {
      // Silent fail
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh conversations (pull-to-refresh).
  Future<void> refreshData() async {
    await fetchConversations();
  }

  /// Start or get existing conversation with a user/helper.
  Future<ChatConversation?> startConversation(String participantId) async {
    try {
      final response = await _api.post<ChatConversation>(
        ApiConstants.chatConversations,
        data: {'participantId': participantId},
        fromData: (data) {
          if (data is Map<String, dynamic>) {
            return ChatConversation.fromJson(data);
          }
          return null;
        },
      );

      if (response.success && response.data != null) {
        // Refresh conversation list
        await fetchConversations();
        return response.data;
      }
    } catch (e) {
      // Silent fail
    }
    return null;
  }

  /// Get the current user ID.
  String? get currentUserId => _authService.currentUser?.id;

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
