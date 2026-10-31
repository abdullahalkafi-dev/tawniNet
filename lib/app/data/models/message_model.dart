import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';

class ChatConversation {
  final String id;
  final List<ChatParticipant> participants;
  final ChatParticipant? otherParticipant;
  final ChatMessage? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participants,
    this.otherParticipant,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List?)
            ?.map((p) {
              // Handle populated objects OR raw ObjectId strings
              if (p is Map) {
                return ChatParticipant.fromJson(Map<String, dynamic>.from(p));
              }
              // Raw ObjectId string — create placeholder
              return ChatParticipant(id: p.toString(), name: '', avatar: '');
            })
            .toList() ??
        [];

    final other = json['otherParticipant'];
    return ChatConversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      participants: participants,
      otherParticipant: other is Map
          ? ChatParticipant.fromJson(Map<String, dynamic>.from(other))
          : null, // otherParticipant must come from backend (populated)
      lastMessage: json['lastMessage'] is Map
          ? ChatMessage.fromJson(Map<String, dynamic>.from(json['lastMessage'] as Map))
          : null,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] == true || (other is Map && other['isOnline'] == true),
      isBlocked: json['isBlocked'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  ChatConversation copyWith({
    int? unreadCount,
    ChatMessage? lastMessage,
    DateTime? lastMessageAt,
    bool? isOnline,
    bool? isBlocked,
  }) {
    return ChatConversation(
      id: id,
      participants: participants,
      otherParticipant: otherParticipant,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get displayName => otherParticipant?.name ?? 'ui_unknown'.tr;
  String get displayImage => otherParticipant?.avatar ?? '';
}

class ChatParticipant {
  final String id;
  final String name;
  final String avatar;

  ChatParticipant({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }
}

/// Where a message I wrote stands.
enum MessageDelivery { sent, sending, failed }

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String type; // text, image, video, offer
  final String? content;
  final List<String> images;
  final String? video;
  final OfferData? offerData;
  final DateTime createdAt;
  final bool isSentByMe;

  /// Ids of the users who read it (the sender is always in there).
  final List<String> readBy;

  /// Phone numbers / links were hidden by the server (no job links the two people yet).
  final bool masked;

  /// Local-only: not yet confirmed by the server / failed to send.
  final MessageDelivery delivery;

  /// Local-only: why it failed (shown to the user).
  final String? errorText;

  /// Local-only: the file paths of a media message, kept so "retry" can re-upload.
  final List<String> localFiles;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName = '',
    this.senderAvatar = '',
    required this.type,
    this.content,
    this.images = const [],
    this.video,
    this.offerData,
    required this.createdAt,
    this.isSentByMe = false,
    this.readBy = const [],
    this.masked = false,
    this.delivery = MessageDelivery.sent,
    this.errorText,
    this.localFiles = const [],
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final conversation = json['conversation'];
    List<String> asUrls(dynamic raw) => (raw is List)
        ? raw
            .map((e) => ApiConstants.resolveImageUrl(e?.toString()) ?? e.toString())
            .toList()
        : <String>[];
    final rawVideo = json['video']?.toString();
    return ChatMessage(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: conversation is Map
          ? (conversation['_id'] ?? '').toString()
          : (conversation ?? '').toString(),
      senderId: sender is Map ? (sender['_id'] ?? '').toString() : (sender ?? '').toString(),
      senderName: sender is Map ? (sender['name'] ?? '').toString() : '',
      senderAvatar: sender is Map ? (sender['avatar'] ?? '').toString() : '',
      type: json['type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      images: asUrls(json['images']),
      video: (rawVideo != null && rawVideo.isNotEmpty)
          ? (ApiConstants.resolveImageUrl(rawVideo) ?? rawVideo)
          : null,
      offerData: json['offerData'] is Map
          ? OfferData.fromJson(Map<String, dynamic>.from(json['offerData'] as Map))
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      isSentByMe: json['isSentByMe'] == true,
      readBy: (json['readBy'] as List?)
              ?.map((r) => r is Map ? (r['userId'] ?? '').toString() : r.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      masked: json['masked'] == true,
    );
  }

  ChatMessage copyWith({
    bool? isSentByMe,
    OfferData? offerData,
    List<String>? readBy,
    MessageDelivery? delivery,
    String? errorText,
    bool clearError = false,
    String? id,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      images: images,
      video: video,
      offerData: offerData ?? this.offerData,
      createdAt: createdAt ?? this.createdAt,
      isSentByMe: isSentByMe ?? this.isSentByMe,
      readBy: readBy ?? this.readBy,
      masked: masked,
      delivery: delivery ?? this.delivery,
      errorText: clearError ? null : (errorText ?? this.errorText),
      localFiles: localFiles,
    );
  }

  /// A copy of a local (not yet confirmed) message that keeps its media files for retry.
  ChatMessage withLocalFiles(List<String> files) => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        type: type,
        content: content,
        images: images,
        video: video,
        createdAt: createdAt,
        isSentByMe: isSentByMe,
        readBy: readBy,
        delivery: delivery,
        errorText: errorText,
        localFiles: files,
      );

  bool get isLocal => id.startsWith('temp_');

  /// Short text for the conversation list ("📷 Photo", "🎥 Video", "🏷 Offer: …").
  String get preview {
    switch (type) {
      case 'image':
        return 'chat_preview_photo'.tr;
      case 'video':
        return 'chat_preview_video'.tr;
      case 'offer':
        return '${'chat_preview_offer'.tr}${offerData?.title.isNotEmpty == true ? ': ${offerData!.title}' : ''}';
      default:
        return content ?? '';
    }
  }
}

class OfferData {
  final String title;
  final String description;

  /// What the helper typed: the total for a fixed offer, the hourly rate for an hourly one.
  final double price;
  final String priceType; // fixed, hourly
  final String date;
  final String startTime;
  final String endTime;
  final String address;
  final double? latitude;
  final double? longitude;
  final String paymentMethod; // cash, online
  final List<String> images;
  final String status; // pending, awaiting_payment, accepted, rejected, cancelled, expired

  /// Bumped on every edit; the client must accept the version they saw.
  final int version;

  /// Total in MAD computed by the server (hourly: rate × hours).
  final double? totalAmount;
  final double? hourlyRate;
  final double? hours;
  final double? feePercentage;
  final double? helperNet;
  final DateTime? expiresAt;

  OfferData({
    required this.title,
    this.description = '',
    required this.price,
    this.priceType = 'fixed',
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.paymentMethod = 'cash',
    this.images = const [],
    this.status = 'pending',
    this.version = 1,
    this.totalAmount,
    this.hourlyRate,
    this.hours,
    this.feePercentage,
    this.helperNet,
    this.expiresAt,
  });

  /// What the client pays in total.
  double get total => totalAmount ?? price;

  bool get isHourly => priceType == 'hourly';

  factory OfferData.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;
    final loc = json['location'];
    if (loc is Map) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    }
    lat = (json['latitude'] as num?)?.toDouble() ?? lat;
    lng = (json['longitude'] as num?)?.toDouble() ?? lng;

    return OfferData(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      priceType: json['priceType']?.toString() ?? 'fixed',
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      images: (json['images'] as List?)
              ?.map((e) => ApiConstants.resolveImageUrl(e?.toString()) ?? e.toString())
              .toList() ??
          [],
      status: json['status']?.toString() ?? 'pending',
      version: (json['version'] as num?)?.toInt() ?? 1,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      hours: (json['hours'] as num?)?.toDouble(),
      feePercentage: (json['feePercentage'] as num?)?.toDouble(),
      helperNet: (json['helperNet'] as num?)?.toDouble(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal(),
    );
  }

  OfferData copyWith({String? status}) => OfferData(
        title: title,
        description: description,
        price: price,
        priceType: priceType,
        date: date,
        startTime: startTime,
        endTime: endTime,
        address: address,
        latitude: latitude,
        longitude: longitude,
        paymentMethod: paymentMethod,
        images: images,
        status: status ?? this.status,
        version: version,
        totalAmount: totalAmount,
        hourlyRate: hourlyRate,
        hours: hours,
        feePercentage: feePercentage,
        helperNet: helperNet,
        expiresAt: expiresAt,
      );

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'priceType': priceType,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'paymentMethod': paymentMethod,
      'images': images,
      'status': status,
    };
  }
}
