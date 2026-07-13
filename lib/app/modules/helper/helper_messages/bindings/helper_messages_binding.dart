import 'package:get/get.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';

class HelperMessagesBinding extends Bindings {
  @override
  void dependencies() {
    // MessagesController is registered permanently in main.dart
    // Just ensure it's accessible
    Get.find<MessagesController>();
  }
}
