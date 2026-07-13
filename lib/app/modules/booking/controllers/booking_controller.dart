import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:get/get.dart';
import '../../../data/models/booking_model.dart';

class BookingController extends GetxController {
  final activeBookings = <Booking>[].obs;
  final completedBookings = <Booking>[].obs;
  final cancelledBookings = <Booking>[].obs;

  Future<void> onChatWithWorker(Booking booking) async {
    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(booking.id);
    if (conversation != null) {
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
