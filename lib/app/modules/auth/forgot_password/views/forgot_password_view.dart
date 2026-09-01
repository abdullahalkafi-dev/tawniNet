import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/forgot_password_controller.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/morocco_phone_field.dart';

import '../../../../core/widgets/theme_toggle_icon_button.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'auth_forget_password'.tr,
                style: AppStyles.h1Of(context).copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered Moroccan mobile number to receive a WhatsApp verification code.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Moroccan Phone Input with Flag Badge
              MoroccoPhoneField(
                label: 'auth_phone'.tr.isNotEmpty && 'auth_phone'.tr != 'auth_phone'
                    ? 'auth_phone'.tr
                    : 'Moroccan Mobile Phone',
                controller: controller.phoneController,
              ),

              const SizedBox(height: 40),
              Obx(
                () => CustomButton(
                  text: 'Send WhatsApp Code',
                  onPressed: controller.sendResetOtp,
                  isLoading: controller.isLoading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
