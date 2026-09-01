import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/morocco_phone_field.dart';
import '../../../../core/widgets/theme_toggle_icon_button.dart';
import '../../../../core/widgets/app_back_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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
              Text('auth_login'.tr, style: AppStyles.h1Of(context).copyWith(fontSize: 34)),
              const SizedBox(height: 8),
              Text(
                'auth_login_subtitle'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Obx(
                        () => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: (val) =>
                              controller.rememberMe.value = val ?? false,
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Text('auth_remember_me'.tr, style: AppStyles.bodyMediumOf(context)),
                    ],
                  ),
                  TextButton(
                    onPressed: controller.goToForgotPassword,
                    child: Text(
                      'auth_forgot_password'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Obx(
                () => CustomButton(
                  text: 'auth_login'.tr,
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("auth_no_account".tr + ' ', style: AppStyles.bodyMediumOf(context)),
                  GestureDetector(
                    onTap: controller.goToSignup,
                    child: Text(
                      'auth_signup'.tr,
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
