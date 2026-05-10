import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final rememberMe = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void login() {
    Get.offAllNamed(Routes.home);
  }

  void loginWithGoogle() {
    // Implement Google login
  }

  void goToSignup() {
    Get.toNamed(Routes.signup);
  }

  void goToForgotPassword() {
    Get.toNamed(Routes.forgotPassword);
  }
}
