import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:get/get.dart';

/// Opens (or creates) the conversation with a helper and shows the chat.
/// Falls back to the helper's profile when messaging isn't available.
Future<void> openChatWithHelper(HelperJob helper) async {
  if (!Get.isRegistered<MessagesController>()) {
    Get.toNamed(Routes.helperProfile, arguments: helper.postedByUserId);
    return;
  }
  final conversation =
      await Get.find<MessagesController>().startConversation(helper.postedByUserId);
  if (conversation == null) return;
  final other = conversation.otherParticipant;
  Get.toNamed(
    Routes.chatDetail,
    arguments: ChatSummary(
      id: conversation.id,
      name: other?.name ?? helper.helperName,
      image: other?.avatar ?? helper.helperImage,
    ),
  );
}
