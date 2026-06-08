import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  String get _role => Get.arguments?['role'] ?? 'user';

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  void signup() {
    if (_role == 'helper') {
      Get.toNamed(Routes.applyAsHelper);
    } else {
      Get.offAllNamed(Routes.home);
    }
  }

  void signupWithGoogle() {
    // Implement Google signup
  }

  void goToLogin() {
    Get.back();
  }
}
