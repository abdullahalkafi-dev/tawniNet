import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'Create Your Account',
                style: AppStyles.h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                'Join 3awniNet and get started in seconds.',
                style: AppStyles.bodyMedium.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                label: 'Full name',
                hint: 'Name',
                controller: controller.nameController,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Email',
                hint: 'Email',
                controller: controller.emailController,
              ),
              const SizedBox(height: 20),
              Obx(
                () => CustomTextField(
                  label: 'Password',
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
                  label: 'Confirm Password',
                  hint: 'Confirm Password',
                  isPassword: true,
                  isVisible: controller.isConfirmPasswordVisible.value,
                  onToggleVisibility: controller.toggleConfirmPasswordVisibility,
                  controller: controller.confirmPasswordController,
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Sign Up',
                onPressed: controller.signup,
              ),
              const SizedBox(height: 30),
              _buildDivider(),
              const SizedBox(height: 30),
              _buildGoogleButton(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ", style: AppStyles.bodyMedium),
                  GestureDetector(
                    onTap: controller.goToLogin,
                    child: Text(
                      'Log In',
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

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: AppStyles.bodyMedium.copyWith(color: Colors.grey)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return CustomButton(
      text: 'Continue with Google',
      onPressed: controller.signupWithGoogle,
      isOutlined: true,
      icon: Image.network(
        'https://cdn1.iconfinder.com/data/icons/google_jfk_icons_by_verexis/128/google.png',
        height: 24,
      ),
    );
  }
}
