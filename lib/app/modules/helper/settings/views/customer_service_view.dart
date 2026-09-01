import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/modules/helper/settings/controllers/customer_service_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomerServiceView extends StatefulWidget {
  const CustomerServiceView({super.key});

  @override
  State<CustomerServiceView> createState() => _CustomerServiceViewState();
}

class _CustomerServiceViewState extends State<CustomerServiceView> {
  final messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerServiceController());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings_contact_us'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final msgs = controller.messages;
              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet. Send a message to contact support.',
                    style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final msg = msgs[index];
                  final isSent = (msg['senderRole'] ?? msg['role']) != 'admin';
                  return _buildMessageBubble(
                    context: context,
                    text: msg['content'] ?? msg['text'] ?? '',
                    isSent: isSent,
                    time: msg['createdAt'] != null
                        ? msg['createdAt'].toString().substring(11, 16)
                        : 'Now',
                  );
                },
              );
            }),
          ),
          _buildInputSection(context, controller),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required BuildContext context,
    required String text,
    required bool isSent,
    required String time,
  }) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isSent ? AppColors.primary : context.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSent ? 16 : 0),
                  bottomRight: Radius.circular(isSent ? 0 : 16),
                ),
                border: isSent ? null : Border.all(color: context.borderSubtle),
              ),
              child: Text(
                text,
                style: AppStyles.bodyMedium.copyWith(
                  color: isSent ? Colors.white : context.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: AppStyles.bodyMedium
                  .copyWith(fontSize: 10, color: context.textHintColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, CustomerServiceController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'chat_type_message'.tr,
                hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: () {
              final text = messageController.text;
              if (text.isNotEmpty) {
                controller.sendMessage(text);
                messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
