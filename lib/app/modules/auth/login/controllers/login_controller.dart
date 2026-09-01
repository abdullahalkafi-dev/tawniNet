import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/utils/morocco_phone_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;

  String get _role => Get.arguments?['role'] ?? Get.find<RoleService>().role;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> _postLoginNavigation() async {
    if (isClosed) return;
    final authService = Get.find<AuthService>();
    await authService.getMe();
    if (isClosed) return;

    final user = authService.currentUser.value;
    final hasLocation = user?.address != null && user!.address!.isNotEmpty;

    if (hasLocation) {
      _navigateToDestination(user!);
    } else {
      Get.offAllNamed(Routes.locationAllow);
    }
  }

  void _navigateToDestination(dynamic user) {
    if (isClosed) return;
    if (user.role == 'helper') {
      switch (user.helperApplicationStatus) {
        case 'approved':
          Get.offAllNamed(Routes.helperHome);
          return;
        case 'pending':
        case 'pending_appeal':
          Get.offAllNamed(Routes.applicationPending);
          return;
        case 'rejected':
          Get.offAllNamed(Routes.applicationRejected);
          return;
        default:
          Get.offAllNamed(Routes.applyAsHelper);
          return;
      }
    }
    Get.offAllNamed(Routes.home);
  }

  Future<void> login() async {
    final phoneInput = phoneController.text.trim();
    final password = passwordController.text;

    final phoneError = MoroccoPhoneHelper.validate(phoneInput);
    if (phoneError != null) {
      _showError(phoneError);
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    final normalizedPhone = MoroccoPhoneHelper.normalize(phoneInput);

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final resultRole = await authService.loginWithPhone(
        phone: normalizedPhone,
        password: password,
      );

      if (resultRole == 'unverified') {
        Get.toNamed(
          Routes.otp,
          arguments: {
            'phone': normalizedPhone,
            'role': _role,
          },
        );
        return;
      }

      await _postLoginNavigation();
    } catch (e) {
      if (isClosed) return;
      _showError(e);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void goToSignup() {
    Get.toNamed(Routes.signup, arguments: {'role': _role});
  }

  void goToForgotPassword() {
    Get.toNamed(Routes.forgotPassword);
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
