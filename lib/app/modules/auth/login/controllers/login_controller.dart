import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final rememberMe = false.obs;

  String get _role => Get.arguments?['role'] ?? Get.find<RoleService>().role;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void login() {
    if (_role == 'helper') {
      Get.offAllNamed(Routes.helperHome);
    } else {
      Get.offAllNamed(Routes.home);
    }
  }

  void loginWithGoogle() {
    // Implement Google login
  }

  void goToSignup() {
    Get.toNamed(Routes.signup, arguments: {'role': _role});
  }

  void goToForgotPassword() {
    Get.toNamed(Routes.forgotPassword);
  }
}
