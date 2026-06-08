import 'package:get/get.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';

class HelperMessagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessagesController>(() => MessagesController());
  }
}
