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
      _showError('ui_please_enter_a_new_password'.tr);
      return;
    }
    if (password.length < kMinPasswordLength) {
      _showError('err_password_too_short'.trParams({'min': '$kMinPasswordLength'}));
      return;
    }
    if (password != confirmPassword) {
      _showError('ui_passwords_do_not_match'.tr);
      return;
    }
    if (_resetToken.isEmpty) {
      _showError('ui_reset_token_is_missing_please_try_again'.tr);
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
        'ui_password_has_been_reset_successfully_please_logi'.tr,
        title: 'booking_success'.tr,
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
