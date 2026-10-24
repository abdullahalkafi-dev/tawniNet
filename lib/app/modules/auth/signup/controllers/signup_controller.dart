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
      _showError('ui_please_enter_your_full_name'.tr);
      return;
    }

    final phoneError = MoroccoPhoneHelper.validate(phoneInput);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    if (password.isEmpty) {
      _showError('ui_please_enter_a_password'.tr);
      return;
    }
    if (password.length < 6) {
      _showError('ui_password_must_be_at_least_6_characters'.tr);
      return;
    }
    if (password != confirmPassword) {
      _showError('ui_passwords_do_not_match'.tr);
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
