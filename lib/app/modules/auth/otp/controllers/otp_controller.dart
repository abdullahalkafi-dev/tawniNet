import 'dart:async';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/utils/morocco_phone_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class OtpController extends GetxController {
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final isLoading = false.obs;
  final canResend = true.obs;
  final resendCooldown = 0.obs;

  Timer? _timer;

  String get phone => Get.arguments?['phone'] ?? Get.arguments?['email'] ?? '';
  String get formattedPhone => MoroccoPhoneHelper.formatDisplay(phone);
  String get _purpose => Get.arguments?['purpose'] ?? 'verify';

  @override
  void onInit() {
    super.onInit();
    // Auto-fill simulation code in debug/test mode
    fillTestOtp();
  }

  void fillTestOtp() {
    const testCode = '123456';
    for (int i = 0; i < otpControllers.length && i < testCode.length; i++) {
      otpControllers[i].text = testCode[i];
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit WhatsApp code');
      return;
    }

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();

      if (_purpose == 'resetPassword') {
        // Forgot password flow: verify reset OTP → get resetToken → reset password
        final resetToken = await authService.verifyResetOtpPhone(
          phone: phone,
          otp: otp,
        );

        if (isClosed) return;
        Get.toNamed(
          Routes.resetPassword,
          arguments: {'resetToken': resetToken, 'phone': phone},
        );
      } else {
        // Registration flow: verify WhatsApp OTP → login
        await authService.verifyPhoneOtp(phone: phone, otp: otp);

        if (isClosed) return;
        Get.offAllNamed(Routes.locationAllow);
      }
    } catch (e) {
      if (isClosed) return;
      _showError(e);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;

    try {
      final authService = Get.find<AuthService>();

      if (_purpose == 'resetPassword') {
        await authService.forgotPasswordPhone(phone: phone);
      } else {
        await authService.resendPhoneOtp(phone: phone);
      }

      if (isClosed) return;

      // Start 60s cooldown
      canResend.value = false;
      resendCooldown.value = 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        resendCooldown.value--;
        if (resendCooldown.value <= 0) {
          canResend.value = true;
          timer.cancel();
        }
      });

      AppSnackbar.showSuccess(
        'A new WhatsApp code has been sent to $formattedPhone',
        title: 'Code Sent',
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    _timer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    super.onClose();
  }
}
