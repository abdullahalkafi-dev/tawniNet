import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';

/// Real-time Socket.IO service for chat messaging.
/// Connects with JWT auth, handles message send/receive, typing indicators, read receipts.
class SocketService extends GetxService {
  final isConnected = false.obs;
  final isConnecting = false.obs;

  IO.Socket? _socket;
  String? _currentUserId;

  // Event callbacks
  Function(ChatMessage)? onNewMessage;
  Function(String conversationId, String userId)? onTypingStart;
  Function(String conversationId, String userId)? onTypingStop;
  Function(String userId, List<String> messageIds)? onMessagesRead;
  Function(String userId, bool isOnline)? onPresenceUpdate;
  Function(String offerMessageId, String status)? onOfferUpdate;

  /// Connect to the socket server with JWT token.
  void connect(String token) {
    if (_socket?.connected == true) return;
    if (isConnecting.value) return;

    isConnecting.value = true;

    // Extract base URL without /api/v1
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api/v1', '');

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .setTransports(['websocket'])
          .build(),
    );

    _socket?.onConnect((_) {
      isConnected.value = true;
      isConnecting.value = false;
    });

    _socket?.onDisconnect((_) {
      isConnected.value = false;
    });

    _socket?.onConnectError((error) {
      isConnected.value = false;
      isConnecting.value = false;
    });

    _socket?.onReconnect((_) {
      isConnected.value = true;
    });

    // ─── Chat Events ───────────────────────────────
    _socket?.on('chat:receive', (data) {
      try {
        final message = ChatMessage.fromJson(data);
        onNewMessage?.call(message);
      } catch (_) {}
    });

    _socket?.on('typing:start', (data) {
      final conversationId = data['conversationId'] as String? ?? '';
      final userId = data['userId'] as String? ?? '';
      onTypingStart?.call(conversationId, userId);
    });

    _socket?.on('typing:stop', (data) {
      final conversationId = data['conversationId'] as String? ?? '';
      final userId = data['userId'] as String? ?? '';
      onTypingStop?.call(conversationId, userId);
    });

    _socket?.on('chat:read', (data) {
      final userId = data['userId'] as String? ?? '';
      final messageIds = (data['messageIds'] as List?)?.cast<String>() ?? [];
      onMessagesRead?.call(userId, messageIds);
    });

    _socket?.on('presence:update', (data) {
      final userId = data['userId'] as String? ?? '';
      final isOnline = data['isOnline'] as bool? ?? false;
      onPresenceUpdate?.call(userId, isOnline);
    });

    _socket?.on('chat:offer-update', (data) {
      try {
        final offerMessageId = data['_id'] as String? ?? '';
        final status = data['offerData']?['status'] as String? ?? '';
        onOfferUpdate?.call(offerMessageId, status);
      } catch (_) {}
    });
  }

  /// Disconnect from the socket server.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    isConnecting.value = false;
  }

  /// Join a conversation room (for receiving real-time messages).
  void joinConversation(String conversationId) {
    _socket?.emit('chat:join', {'conversationId': conversationId});
  }

  /// Leave a conversation room.
  void leaveConversation(String conversationId) {
    _socket?.emit('chat:leave', {'conversationId': conversationId});
  }

  /// Send a message via socket.
  void sendMessage({
    required String conversationId,
    required String type,
    String? content,
    List<String>? images,
    String? video,
  }) {
    _socket?.emit('chat:send', {
      'conversationId': conversationId,
      'type': type,
      if (content != null) 'content': content,
      if (images != null) 'images': images,
      if (video != null) 'video': video,
    });
  }

  /// Send typing start indicator.
  void startTyping(String conversationId) {
    _socket?.emit('typing:start', {'conversationId': conversationId});
  }

  /// Send typing stop indicator.
  void stopTyping(String conversationId) {
    _socket?.emit('typing:stop', {'conversationId': conversationId});
  }

  /// Mark messages as read.
  void markRead(String conversationId, List<String> messageIds) {
    _socket?.emit('chat:read', {
      'conversationId': conversationId,
      'messageIds': messageIds,
    });
  }

  /// Emit a generic event.
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  /// Listen to a generic event.
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  /// Remove listener for a generic event.
  void off(String event) {
    _socket?.off(event);
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
