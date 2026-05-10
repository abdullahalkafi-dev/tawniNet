import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpController extends GetxController {
  final otpControllers = List.generate(4, (index) => TextEditingController());

  void verifyOtp() {
    Get.toNamed(Routes.resetPassword);
  }

  void resendOtp() {
    // Implement resend logic
  }
}
