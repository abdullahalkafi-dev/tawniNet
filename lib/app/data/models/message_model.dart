class ChatConversation {
  final String id;
  final List<ChatParticipant> participants;
  final ChatParticipant? otherParticipant;
  final ChatMessage? lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participants,
    this.otherParticipant,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final participants = (json['participants'] as List?)
            ?.map((p) {
              // Handle populated objects OR raw ObjectId strings
              if (p is Map<String, dynamic>) {
                return ChatParticipant.fromJson(p);
              }
              // Raw ObjectId string — create placeholder
              return ChatParticipant(id: p.toString(), name: '', avatar: '');
            })
            .toList() ??
        [];

    return ChatConversation(
      id: json['_id'] ?? json['id'] ?? '',
      participants: participants,
      otherParticipant: json['otherParticipant'] != null
          ? ChatParticipant.fromJson(json['otherParticipant'])
          : null, // otherParticipant must come from backend (populated)
      lastMessage: json['lastMessage'] != null &&
              json['lastMessage'] is Map<String, dynamic>
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt']) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  ChatConversation copyWith({
    int? unreadCount,
    ChatMessage? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ChatConversation(
      id: id,
      participants: participants,
      otherParticipant: otherParticipant,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get displayName => otherParticipant?.name ?? 'Unknown';
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
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'] ?? '',
    );
  }
}

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
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversation'] ?? '',
      senderId: sender is Map ? sender['_id'] ?? '' : sender ?? '',
      senderName: sender is Map ? (sender['name'] ?? '') : '',
      senderAvatar: sender is Map ? (sender['avatar'] ?? '') : '',
      type: json['type'] ?? 'text',
      content: json['content'],
      images: (json['images'] as List?)?.cast<String>() ?? [],
      video: json['video'],
      offerData: json['offerData'] != null
          ? OfferData.fromJson(json['offerData'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      isSentByMe: json['isSentByMe'] ?? false,
    );
  }

  ChatMessage copyWith({bool? isSentByMe}) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      type: type,
      content: content,
      images: images,
      video: video,
      offerData: offerData,
      createdAt: createdAt,
      isSentByMe: isSentByMe ?? this.isSentByMe,
    );
  }
}

class OfferData {
  final String title;
  final String description;
  final double price;
  final String priceType; // fixed, hourly
  final String date;
  final String startTime;
  final String endTime;
  final String paymentMethod; // cash, online
  final List<String> images;
  final String status; // pending, accepted, rejected, cancelled

  OfferData({
    required this.title,
    this.description = '',
    required this.price,
    this.priceType = 'fixed',
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    this.paymentMethod = 'cash',
    this.images = const [],
    this.status = 'pending',
  });

  factory OfferData.fromJson(Map<String, dynamic> json) {
    return OfferData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      priceType: json['priceType'] ?? 'fixed',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      images: (json['images'] as List?)?.cast<String>() ?? [],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'priceType': priceType,
      'startTime': startTime,
      'endTime': endTime,
      'paymentMethod': paymentMethod,
      'images': images,
    };
  }
}
