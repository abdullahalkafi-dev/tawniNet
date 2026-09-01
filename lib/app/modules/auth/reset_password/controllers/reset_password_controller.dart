import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class ResetPasswordController extends GetxController {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  String get _resetToken => Get.arguments?['resetToken'] ?? '';

  void togglePasswordVisibility() =>
      isPasswordVisible.value = !isPasswordVisible.value;
  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  Future<void> resetPassword() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (password.isEmpty) {
      _showError('Please enter a new password');
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
    if (_resetToken.isEmpty) {
      _showError('Reset token is missing. Please try again.');
      return;
    }

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      await authService.resetPasswordPhone(
        resetToken: _resetToken,
        newPassword: password,
      );

      if (isClosed) return;
      AppSnackbar.showSuccess(
        'Password has been reset successfully. Please login.',
        title: 'Success',
      );

      Get.offAllNamed(Routes.login, arguments: {'role': Get.find<RoleService>().role});
    } catch (e) {
      if (isClosed) return;
      _showError(e);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
