import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperProfileController extends GetxController {
  final messageController = TextEditingController();

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      print('Message sent: ${messageController.text}');
      messageController.clear();
    }
  }
}
