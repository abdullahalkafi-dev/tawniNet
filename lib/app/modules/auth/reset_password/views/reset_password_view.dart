import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reset_password_controller.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

import '../../../../core/widgets/theme_toggle_icon_button.dart';

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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ThemeToggleIconButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'auth_reset_password'.tr,
                style: AppStyles.h1Of(context).copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'auth_reset_subtitle'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 16),
              ),
              const SizedBox(height: 40),
              Obx(
                () => CustomTextField(
                  label: 'auth_new_password'.tr,
                  hint: 'auth_password'.tr,
                  isPassword: true,
                  isVisible: controller.isPasswordVisible.value,
                  onToggleVisibility: controller.togglePasswordVisibility,
                  controller: controller.passwordController,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => CustomTextField(
                  label: 'auth_confirm_new_password'.tr,
                  hint: 'auth_confirm_password'.tr,
                  isPassword: true,
                  isVisible: controller.isConfirmPasswordVisible.value,
                  onToggleVisibility: controller.toggleConfirmPasswordVisibility,
                  controller: controller.confirmPasswordController,
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'auth_update_password'.tr,
                onPressed: controller.resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
