import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/morocco_phone_field.dart';
import '../../../../core/widgets/theme_toggle_icon_button.dart';
import '../../../../core/widgets/app_back_button.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Top Bar with Minimal Back Button & Theme Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppBackButton(
                    onPressed: () => Get.offAllNamed('/role-selection'),
                  ),
                  const ThemeToggleIconButton(),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'auth_create_account'.tr,
                style: AppStyles.h1Of(context).copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'auth_signup_subtitle'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              CustomTextField(
                label: 'auth_full_name'.tr,
                hint: 'auth_name'.tr,
                controller: controller.nameController,
              ),
              const SizedBox(height: 20),

              // Moroccan Phone Input with Flag Badge
              MoroccoPhoneField(
                label: 'auth_phone'.tr.isNotEmpty && 'auth_phone'.tr != 'auth_phone'
                    ? 'auth_phone'.tr
                    : 'Moroccan Mobile Phone',
                controller: controller.phoneController,
              ),

              const SizedBox(height: 20),
              Obx(
                () => CustomTextField(
                  label: 'auth_password'.tr,
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
                  label: 'auth_confirm_password'.tr,
                  hint: 'auth_confirm_password'.tr,
                  isPassword: true,
                  isVisible: controller.isConfirmPasswordVisible.value,
                  onToggleVisibility:
                      controller.toggleConfirmPasswordVisibility,
                  controller: controller.confirmPasswordController,
                ),
              ),
              const SizedBox(height: 28),
              Obx(
                () => CustomButton(
                  text: 'auth_signup'.tr,
                  onPressed: controller.signup,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "auth_has_account".tr + ' ',
                    style: AppStyles.bodyMediumOf(context),
                  ),
                  GestureDetector(
                    onTap: controller.goToLogin,
                    child: Text(
                      'auth_log_in'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
