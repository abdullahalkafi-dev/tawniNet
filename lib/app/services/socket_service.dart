import 'dart:async';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';

/// Real-time Socket.IO service for chat messaging.
/// Uses broadcast streams so multiple listeners can receive events.
class SocketService extends GetxService {
  final isConnected = false.obs;
  final isConnecting = false.obs;

  IO.Socket? _socket;

  // Broadcast streams — multiple listeners can subscribe
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingStartController = StreamController<Map<String, String>>.broadcast();
  final _typingStopController = StreamController<Map<String, String>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<ChatMessage> get onNewMessage => _messageController.stream;
  Stream<Map<String, String>> get onTypingStart => _typingStartController.stream;
  Stream<Map<String, String>> get onTypingStop => _typingStopController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readController.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdate => _offerUpdateController.stream;
  IO.Socket? get socket => _socket;

  /// Connect to the socket server with JWT token.
  void connect(String token) {
    if (_socket?.connected == true) return;
    if (isConnecting.value) return;

    // Disconnect existing socket before reconnecting to prevent duplicate listeners
    _removeChatListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    isConnecting.value = true;

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

    _setupChatListeners();
  }

  void _setupChatListeners() {
    _socket?.on('chat:receive', (data) {
      try {
        final message = ChatMessage.fromJson(data);
        _messageController.add(message);
      } catch (_) {}
    });

    _socket?.on('typing:start', (data) {
      _typingStartController.add({
        'conversationId': data['conversationId'] ?? '',
        'userId': data['userId'] ?? '',
      });
    });

    _socket?.on('typing:stop', (data) {
      _typingStopController.add({
        'conversationId': data['conversationId'] ?? '',
        'userId': data['userId'] ?? '',
      });
    });

    _socket?.on('chat:read', (data) {
      _readController.add({
        'userId': data['userId'] ?? '',
        'messageIds': (data['messageIds'] as List?)?.cast<String>() ?? [],
      });
    });

    _socket?.on('presence:update', (data) {
      _presenceController.add({
        'userId': data['userId'] ?? '',
        'isOnline': data['isOnline'] ?? false,
      });
    });

    _socket?.on('chat:offer-update', (data) {
      _offerUpdateController.add(data);
    });
  }

  void _removeChatListeners() {
    _socket?.off('chat:receive');
    _socket?.off('typing:start');
    _socket?.off('typing:stop');
    _socket?.off('chat:read');
    _socket?.off('presence:update');
    _socket?.off('chat:offer-update');
  }

  /// Disconnect from the socket server.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    isConnecting.value = false;
  }

  /// Join a conversation room.
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

  @override
  void onClose() {
    disconnect();
    _messageController.close();
    _typingStartController.close();
    _typingStopController.close();
    _readController.close();
    _presenceController.close();
    _offerUpdateController.close();
    super.onClose();
  }
}
