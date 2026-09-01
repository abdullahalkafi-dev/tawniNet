import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/utils/morocco_phone_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class SignupController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  String get _role => Get.arguments?['role'] ?? 'user';

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  Future<void> signup() async {
    final name = nameController.text.trim();
    final phoneInput = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }

    final phoneError = MoroccoPhoneHelper.validate(phoneInput);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter a password');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    final normalizedPhone = MoroccoPhoneHelper.normalize(phoneInput);

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final result = await authService.registerWithPhone(
        phone: normalizedPhone,
        password: password,
        name: name,
      );

      if (isClosed) return;
      Get.toNamed(
        Routes.otp,
        arguments: {
          'phone': result['phone'] ?? normalizedPhone,
          'role': _role,
        },
      );
    } catch (e) {
      if (isClosed) return;
      _showError(e);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void goToLogin() {
    Get.back();
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
