import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/utils/morocco_phone_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class ForgotPasswordController extends GetxController {
  final phoneController = TextEditingController();
  final isLoading = false.obs;

  Future<void> sendResetOtp() async {
    final phoneInput = phoneController.text.trim();

    final phoneError = MoroccoPhoneHelper.validate(phoneInput);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    final normalizedPhone = MoroccoPhoneHelper.normalize(phoneInput);

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      await authService.forgotPasswordPhone(phone: normalizedPhone);

      if (isClosed) return;
      Get.toNamed(
        Routes.otp,
        arguments: {
          'phone': normalizedPhone,
          'purpose': 'resetPassword',
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

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
