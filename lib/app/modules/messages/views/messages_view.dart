import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/conversation_list.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessagesView extends GetView<MessagesController> {
  const MessagesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (controller.isSearching.value) {
            return TextField(
              autofocus: true,
              style: TextStyle(color: context.textPrimaryColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'messages_search'.tr,
                hintStyle: TextStyle(color: context.textHintColor),
                border: InputBorder.none,
              ),
              onChanged: (value) => controller.searchQuery.value = value,
            );
          }
          return Text(
            'messages_title'.tr,
            style: AppStyles.h1Of(context).copyWith(fontSize: 24),
          );
        }),
        actions: [
          Obx(() {
            if (controller.isSearching.value) {
              return IconButton(
                icon: Icon(Icons.close, color: context.textPrimaryColor),
                onPressed: () {
                  controller.isSearching.value = false;
                  controller.searchQuery.value = '';
                },
              );
            }
            return IconButton(
              icon: Icon(Icons.search, color: context.textPrimaryColor),
              onPressed: () => controller.isSearching.value = true,
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: ConversationList(
        controller: controller,
        chatRoute: Routes.chatDetail,
        emptyHint: 'ui_start_a_conversation_with_a_helper_from'.tr,
      ),
    );
  }
}
