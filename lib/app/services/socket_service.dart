import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/message_model.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/storage_service.dart';

/// Real-time Socket.IO service.
///
/// - Reconnects forever with back-off (and falls back to HTTP long-polling on
///   networks that block WebSockets).
/// - When the access token expired while the phone was offline it is renewed
///   before the next attempt.
/// - Every (re)connection fires [onSynced] so screens can fetch what they
///   missed — events are never replayed by the server.
/// Uses broadcast streams so multiple listeners can receive events.
class SocketService extends GetxService {
  final isConnected = false.obs;
  final isConnecting = false.obs;

  IO.Socket? _socket;
  String? _token;
  bool _everConnected = false;
  DateTime? _lastAuthRecovery;

  // Rooms to re-join after reconnect
  final Set<String> _joinedConversations = {};
  final Set<String> _joinedSupportTickets = {};
  final Set<String> _joinedTrackingJobs = {};

  // Broadcast streams — multiple listeners can subscribe
  final _messageController = StreamController<ChatMessage>.broadcast();
  final _typingStartController = StreamController<Map<String, String>>.broadcast();
  final _typingStopController = StreamController<Map<String, String>>.broadcast();
  final _readController = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController = StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _newNearbyJobController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobUnavailableController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobCompletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _jobCancelledController = StreamController<Map<String, dynamic>>.broadcast();
  final _walletTopupController = StreamController<Map<String, dynamic>>.broadcast();
  final _supportMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _supportStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _trackingLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _trackingEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _paymentVerifiedController = StreamController<Map<String, dynamic>>.broadcast();
  final _kycUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatErrorController = StreamController<Map<String, dynamic>>.broadcast();
  final _syncedController = StreamController<void>.broadcast();

  // Public streams
  Stream<ChatMessage> get onNewMessage => _messageController.stream;
  Stream<Map<String, String>> get onTypingStart => _typingStartController.stream;
  Stream<Map<String, String>> get onTypingStop => _typingStopController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _readController.stream;
  Stream<Map<String, dynamic>> get onPresenceUpdate => _presenceController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdate => _offerUpdateController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onNewNearbyJob => _newNearbyJobController.stream;
  Stream<Map<String, dynamic>> get onJobAccepted => _jobAcceptedController.stream;
  /// `{jobId, status}` — something changed on a job you are part of.
  Stream<Map<String, dynamic>> get onJobUpdated => _jobUpdatedController.stream;
  /// `{jobId}` — a job you were offered was taken / cancelled / expired.
  Stream<Map<String, dynamic>> get onJobUnavailable => _jobUnavailableController.stream;
  Stream<Map<String, dynamic>> get onJobCompleted => _jobCompletedController.stream;
  Stream<Map<String, dynamic>> get onJobCancelled => _jobCancelledController.stream;
  Stream<Map<String, dynamic>> get onWalletTopupSuccess => _walletTopupController.stream;
  Stream<Map<String, dynamic>> get onSupportMessage => _supportMessageController.stream;
  Stream<Map<String, dynamic>> get onSupportStatus => _supportStatusController.stream;
  Stream<Map<String, dynamic>> get onTrackingLocationUpdate => _trackingLocationController.stream;
  Stream<Map<String, dynamic>> get onTrackingEnded => _trackingEndedController.stream;
  Stream<Map<String, dynamic>> get onPaymentVerified => _paymentVerifiedController.stream;
  Stream<Map<String, dynamic>> get onKycUpdated => _kycUpdatedController.stream;
  Stream<Map<String, dynamic>> get onChatError => _chatErrorController.stream;

  /// Fires after every successful connection (first and re-connections):
  /// fetch whatever you may have missed while offline.
  Stream<void> get onSynced => _syncedController.stream;

  IO.Socket? get socket => _socket;

  /// Connect to the socket server with JWT token.
  void connect(String token) {
    _token = token;
    if (_socket?.connected == true) return;
    if (isConnecting.value && _socket != null) return;

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
          // WebSocket first; long-polling when a network blocks it.
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(15000)
          .setReconnectionAttempts(double.infinity)
          .build(),
    );

    _socket?.onConnect((_) {
      isConnected.value = true;
      isConnecting.value = false;
      _rejoinRooms();
      _everConnected = true;
      _syncedController.add(null);
    });

    _socket?.onDisconnect((reason) {
      isConnected.value = false;
      // The server closed us on purpose (suspended account, ended session):
      // no automatic retry from socket.io, so recover manually if the account is still valid.
      if (reason == 'io server disconnect') {
        _recoverAuthAndReconnect();
      }
    });

    _socket?.onConnectError((error) {
      isConnected.value = false;
      isConnecting.value = false;
      final text = error?.toString() ?? '';
      if (text.contains('Unauthorized')) {
        _recoverAuthAndReconnect();
      }
    });

    _setupChatListeners();
  }

  /// Make sure we are connected (app came to the foreground, network changed…).
  Future<void> ensureConnected() async {
    if (_socket?.connected == true) return;
    final token = _token ?? await Get.find<StorageService>().getAccessToken();
    if (token == null || token.isEmpty) return;
    if (_socket == null) {
      connect(token);
    } else {
      _socket!.auth = {'token': token};
      _socket!.connect();
    }
  }

  /// A new access token is available (after a refresh): next (re)connection uses it.
  void updateToken(String token) {
    _token = token;
    _socket?.auth = {'token': token};
  }

  /// The handshake was refused: the access token is probably expired. Renew it
  /// (any authenticated call triggers the refresh interceptor) and try again.
  /// Rate-limited so a really ended session does not loop.
  Future<void> _recoverAuthAndReconnect() async {
    final now = DateTime.now();
    if (_lastAuthRecovery != null && now.difference(_lastAuthRecovery!).inSeconds < 30) return;
    _lastAuthRecovery = now;
    try {
      if (!Get.isRegistered<ApiClient>()) return;
      await Get.find<ApiClient>().get(ApiConstants.userMe);
      final token = await Get.find<StorageService>().getAccessToken();
      if (token == null || token.isEmpty) return; // logged out meanwhile
      updateToken(token);
      _socket?.connect();
    } catch (e) {
      if (kDebugMode) debugPrint('[Socket] auth recovery failed: $e');
    }
  }

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  void _forward(String event, StreamController<Map<String, dynamic>> sink) {
    _socket?.on(event, (data) {
      if (data is Map) sink.add(Map<String, dynamic>.from(data));
    });
  }

  void _setupChatListeners() {
    _socket?.on('chat:receive', (data) {
      try {
        final message = ChatMessage.fromJson(data);
        _messageController.add(message);
      } catch (_) {}
    });

    _socket?.on('typing:start', (data) {
      final m = _asMap(data);
      _typingStartController.add({
        'conversationId': m['conversationId']?.toString() ?? '',
        'userId': m['userId']?.toString() ?? '',
      });
    });

    _socket?.on('typing:stop', (data) {
      final m = _asMap(data);
      _typingStopController.add({
        'conversationId': m['conversationId']?.toString() ?? '',
        'userId': m['userId']?.toString() ?? '',
      });
    });

    _socket?.on('chat:read', (data) {
      final m = _asMap(data);
      _readController.add({
        'userId': m['userId']?.toString() ?? '',
        'conversationId': m['conversationId']?.toString() ?? '',
        'messageIds': (m['messageIds'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      });
    });

    _socket?.on('presence:update', (data) {
      final m = _asMap(data);
      _presenceController.add({
        'userId': m['userId']?.toString() ?? '',
        'isOnline': m['isOnline'] == true,
      });
    });

    _forward('chat:offer-update', _offerUpdateController);
    _forward('chat:conversation_updated', _conversationUpdatedController);
    _forward('job:new_nearby', _newNearbyJobController);
    _forward('job:accepted', _jobAcceptedController);
    _forward('job:updated', _jobUpdatedController);
    _forward('job:unavailable', _jobUnavailableController);
    _forward('job:completed', _jobCompletedController);
    _forward('job:cancelled', _jobCancelledController);
    _forward('wallet:topup_success', _walletTopupController);
    _forward('support:message', _supportMessageController);
    _forward('support:status', _supportStatusController);
    _forward('tracking:location_update', _trackingLocationController);
    _forward('tracking:ended', _trackingEndedController);
    _forward('job:payment_verified', _paymentVerifiedController);
    _forward('offer:payment_verified', _paymentVerifiedController);
    _forward('kyc:updated', _kycUpdatedController);
    _forward('chat:error', _chatErrorController);
  }

  static const _events = [
    'chat:receive',
    'typing:start',
    'typing:stop',
    'chat:read',
    'presence:update',
    'chat:offer-update',
    'chat:conversation_updated',
    'job:new_nearby',
    'job:accepted',
    'job:updated',
    'job:unavailable',
    'job:completed',
    'job:cancelled',
    'wallet:topup_success',
    'support:message',
    'support:status',
    'tracking:location_update',
    'tracking:ended',
    'job:payment_verified',
    'offer:payment_verified',
    'kyc:updated',
    'chat:error',
  ];

  void _removeChatListeners() {
    for (final e in _events) {
      _socket?.off(e);
    }
  }

  /// Disconnect from the socket server.
  /// Clears joined rooms so the next login cannot re-join the previous user's chats.
  void disconnect() {
    _joinedConversations.clear();
    _joinedSupportTickets.clear();
    _joinedTrackingJobs.clear();
    _token = null;
    _everConnected = false;
    _removeChatListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    isConnecting.value = false;
  }

  /// True after the first successful connection of this login session.
  bool get hasConnectedBefore => _everConnected;

  /// Re-join tracked rooms after reconnect (Socket.IO forgets membership).
  void _rejoinRooms() {
    for (final id in _joinedConversations) {
      _socket?.emit('chat:join', {'conversationId': id});
    }
    for (final id in _joinedSupportTickets) {
      _socket?.emit('support:join', {'ticketId': id});
    }
    for (final id in _joinedTrackingJobs) {
      _socket?.emit('tracking:join', {'jobId': id});
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

  /// Join a job tracking room.
  void joinTracking(String jobId) {
    if (jobId.isEmpty) return;
    _joinedTrackingJobs.add(jobId);
    _socket?.emit('tracking:join', {'jobId': jobId});
  }

  /// Leave a job tracking room.
  void leaveTracking(String jobId) {
    if (jobId.isEmpty) return;
    _joinedTrackingJobs.remove(jobId);
    _socket?.emit('tracking:leave', {'jobId': jobId});
  }

  /// Emit periodic or on-move helper location ping.
  void emitHelperLocationPing(Map<String, dynamic> data) {
    _socket?.emit('helper:location_ping', data);
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
    _conversationUpdatedController.close();
    _newNearbyJobController.close();
    _jobAcceptedController.close();
    _jobUpdatedController.close();
    _jobUnavailableController.close();
    _jobCompletedController.close();
    _jobCancelledController.close();
    _walletTopupController.close();
    _supportMessageController.close();
    _supportStatusController.close();
    _trackingLocationController.close();
    _trackingEndedController.close();
    _paymentVerifiedController.close();
    _kycUpdatedController.close();
    _chatErrorController.close();
    _syncedController.close();
    super.onClose();
  }
}
