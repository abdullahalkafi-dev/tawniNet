import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reset_password_controller.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Reset Password',
                style: AppStyles.h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new password to secure your account',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 40),
              Obx(
                () => CustomTextField(
                  label: 'New Password',
                  hint: 'Password',
                  isPassword: true,
                  isVisible: controller.isPasswordVisible.value,
                  onToggleVisibility: controller.togglePasswordVisibility,
                  controller: controller.passwordController,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => CustomTextField(
                  label: 'Confirm New Password',
                  hint: 'Confirm Password',
                  isPassword: true,
                  isVisible: controller.isConfirmPasswordVisible.value,
                  onToggleVisibility: controller.toggleConfirmPasswordVisibility,
                  controller: controller.confirmPasswordController,
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Update Password',
                onPressed: controller.resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
