import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/forgot_password_controller.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Forget Password',
                style: AppStyles.h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your email to reset password',
                style: AppStyles.bodyMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                label: 'Email',
                hint: 'Email',
                controller: controller.emailController,
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Reset Password',
                onPressed: controller.resetPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
