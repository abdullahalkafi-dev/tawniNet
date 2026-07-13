import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:get/get.dart';
import '../../../data/models/booking_model.dart';

class BookingController extends GetxController {
  final activeBookings = <Booking>[
    Booking(
      id: '1',
      workerUserId: '',
      workerName: 'Ethan Carter',
      workerImage: 'https://i.pravatar.cc/150?u=ethan1',
      category: 'Cleaner',
      status: BookingStatus.inProgress,
      jobType: 'Plumber',
      date: 'Mar 12, 2026',
      time: '10:00AM - 12:00 PM',
      location: '276 New Avu.. Park, New York',
      budget: 100,
      description: 'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum...',
      photos: [
        'https://i.pravatar.cc/150?u=ethan1',
        'https://i.pravatar.cc/150?u=ethan1',
        'https://i.pravatar.cc/150?u=ethan1',
      ],
    ),
    Booking(
      id: '2',
      workerUserId: '',
      workerName: 'Ethan Carter',
      workerImage: 'https://i.pravatar.cc/150?u=ethan2',
      category: 'Plumber',
      status: BookingStatus.inProgress,
      jobType: 'Plumber',
      date: 'Mar 12, 2026',
      time: '10:00AM - 12:00 PM',
      location: '276 New Avu.. Park, New York',
      budget: 100,
      description: 'Tasks Required...',
      photos: [],
    ),
  ].obs;

  final completedBookings = <Booking>[
    Booking(
      id: '3',
      workerUserId: '',
      workerName: 'Ethan Carter',
      workerImage: 'https://i.pravatar.cc/150?u=ethan3',
      category: 'Painter',
      status: BookingStatus.completed,
      jobType: 'Painting',
      date: 'Mar 10, 2026',
      time: '10:00AM - 12:00 PM',
      location: 'Downtown Area',
      budget: 150,
      description: 'Deep painting...',
      photos: [],
    ),
  ].obs;

  final cancelledBookings = <Booking>[
    Booking(
      id: '4',
      workerUserId: '',
      workerName: 'Sampura',
      workerImage: 'https://i.pravatar.cc/150?u=sampura',
      category: 'Cleaner',
      status: BookingStatus.cancelled,
      jobType: 'Cleaning',
      date: 'March 12, 2026',
      time: '10:00AM - 12:00 PM',
      location: '123 Elm Street, Morocco',
      budget: 85,
      description: 'Lorem ipsum dolor sit amet consectetur...',
      photos: [],
    ),
  ].obs;

  Future<void> onChatWithWorker(Booking booking) async {
    if (booking.workerUserId.isEmpty) return;

    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(booking.workerUserId);
    if (conversation != null && !Get.isSnackbarOpen) {
      final other = conversation.otherParticipant;
      Get.toNamed(
        Routes.chatDetail,
        arguments: ChatSummary(
          id: conversation.id,
          name: other?.name ?? booking.workerName,
          image: other?.avatar ?? booking.workerImage,
        ),
      );
    }
  }

  void cancelBooking(String id) {
    print('Booking $id cancelled');
  }
}
