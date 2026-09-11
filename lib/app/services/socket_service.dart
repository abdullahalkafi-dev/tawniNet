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

  // Rooms to re-join after reconnect
  final Set<String> _joinedConversations = {};
  final Set<String> _joinedSupportTickets = {};

  // Broadcast streams — multiple listeners can subscribe
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingStartController = StreamController<Map<String, String>>.broadcast();
  final _typingStopController = StreamController<Map<String, String>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _newNearbyJobController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobCompletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _walletTopupController = StreamController<Map<String, dynamic>>.broadcast();
  final _supportMessageController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<ChatMessage> get onNewMessage => _messageController.stream;
  Stream<Map<String, String>> get onTypingStart => _typingStartController.stream;
  Stream<Map<String, String>> get onTypingStop => _typingStopController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readController.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdate => _offerUpdateController.stream;
  Stream<Map<String, dynamic>> get onNewNearbyJob => _newNearbyJobController.stream;
  Stream<Map<String, dynamic>> get onJobAccepted => _jobAcceptedController.stream;
  Stream<Map<String, dynamic>> get onJobCompleted => _jobCompletedController.stream;
  Stream<Map<String, dynamic>> get onJobCancelled => _jobCancelledController.stream;
  Stream<Map<String, dynamic>> get onWalletTopupSuccess => _walletTopupController.stream;
  Stream<Map<String, dynamic>> get onSupportMessage => _supportMessageController.stream;
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
      _rejoinRooms();
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
      _rejoinRooms();
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
      if (data is Map<String, dynamic>) {
        _offerUpdateController.add(data);
      }
    });

    _socket?.on('job:new_nearby', (data) {
      if (data is Map<String, dynamic>) {
        _newNearbyJobController.add(data);
      }
    });

    _socket?.on('job:accepted', (data) {
      if (data is Map<String, dynamic>) {
        _jobAcceptedController.add(data);
      }
    });

    _socket?.on('job:completed', (data) {
      if (data is Map<String, dynamic>) {
        _jobCompletedController.add(data);
      }
    });

    _socket?.on('job:cancelled', (data) {
      if (data is Map<String, dynamic>) {
        _jobCancelledController.add(data);
      }
    });

    _socket?.on('wallet:topup_success', (data) {
      if (data is Map<String, dynamic>) {
        _walletTopupController.add(data);
      }
    });

    _socket?.on('support:message', (data) {
      if (data is Map<String, dynamic>) {
        _supportMessageController.add(data);
      } else if (data is Map) {
        _supportMessageController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  void _removeChatListeners() {
    _socket?.off('chat:receive');
    _socket?.off('typing:start');
    _socket?.off('typing:stop');
    _socket?.off('chat:read');
    _socket?.off('presence:update');
    _socket?.off('chat:offer-update');
    _socket?.off('job:new_nearby');
    _socket?.off('job:accepted');
    _socket?.off('job:completed');
    _socket?.off('job:cancelled');
    _socket?.off('wallet:topup_success');
    _socket?.off('support:message');
  }

  /// Disconnect from the socket server.
  /// Clears joined rooms so the next login cannot re-join the previous user's chats.
  void disconnect() {
    _joinedConversations.clear();
    _joinedSupportTickets.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    isConnecting.value = false;
  }

  /// Re-join tracked rooms after reconnect (Socket.IO forgets membership).
  void _rejoinRooms() {
    for (final id in _joinedConversations) {
      _socket?.emit('chat:join', {'conversationId': id});
    }
    for (final id in _joinedSupportTickets) {
      _socket?.emit('support:join', {'ticketId': id});
    }
  }

  /// Join a conversation room.
  void joinConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _joinedConversations.add(conversationId);
    _socket?.emit('chat:join', {'conversationId': conversationId});
  }

  /// Leave a conversation room.
  void leaveConversation(String conversationId) {
    _joinedConversations.remove(conversationId);
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

  /// Join a support ticket room.
  void joinSupportRoom(String ticketId) {
    if (ticketId.isEmpty) return;
    _joinedSupportTickets.add(ticketId);
    _socket?.emit('support:join', {'ticketId': ticketId});
  }

  /// Leave a support ticket room.
  void leaveSupportRoom(String ticketId) {
    _joinedSupportTickets.remove(ticketId);
    _socket?.emit('support:leave', {'ticketId': ticketId});
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
    _newNearbyJobController.close();
    _jobAcceptedController.close();
    _jobCompletedController.close();
    _jobCancelledController.close();
    _walletTopupController.close();
    _supportMessageController.close();
    super.onClose();
  }
}
