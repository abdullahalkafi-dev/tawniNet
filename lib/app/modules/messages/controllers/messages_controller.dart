import 'package:get/get.dart';

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
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    this.isOnline = false,
  });
}

class MessagesController extends GetxController {
  final chats = <ChatSummary>[
    ChatSummary(
      id: '1',
      name: 'Jacob Jones',
      image: 'https://i.pravatar.cc/150?u=jacob',
      lastMessage: 'Get ready to rock and roll with us! We...',
      time: '2:30 PM',
      unreadCount: 1,
      isOnline: true,
    ),
    ChatSummary(
      id: '2',
      name: 'Robert Fox',
      image: 'https://i.pravatar.cc/150?u=robert',
      lastMessage: 'About what we spoke the other time ...',
      time: '2:30 PM',
      unreadCount: 1,
    ),
    ChatSummary(
      id: '3',
      name: 'Guy Hawkins',
      image: 'https://i.pravatar.cc/150?u=guy',
      lastMessage: 'Just checking up on you',
      time: '2:30 PM',
      unreadCount: 1,
    ),
    ChatSummary(
      id: '4',
      name: 'Leslie Alexander',
      image: 'https://i.pravatar.cc/150?u=leslie',
      lastMessage: 'How are okay in doing this morning?',
      time: '2:30 PM',
      unreadCount: 1,
    ),
    ChatSummary(
      id: '5',
      name: 'Jacob Jones',
      image: 'https://i.pravatar.cc/150?u=jacob2',
      lastMessage: 'Are you okay in this difficult times',
      time: '2:30 PM',
      unreadCount: 0,
    ),
    ChatSummary(
      id: '6',
      name: 'Albert Flores',
      image: 'https://i.pravatar.cc/150?u=albert',
      lastMessage: 'Hi',
      time: '2:30 PM',
      unreadCount: 0,
    ),
  ].obs;
}
