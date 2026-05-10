import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                'Login',
                style: AppStyles.h1.copyWith(fontSize: 36),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to my account',
                style: AppStyles.bodyMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 40),
              CustomTextField(
                label: 'Email',
                hint: 'Email',
                controller: controller.emailController,
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Obx(
                        () => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: (val) => controller.rememberMe.value = val ?? false,
                          activeColor: AppColors.primary,
                        ),
                      ),
                      Text('Remember Me', style: AppStyles.bodyMedium),
                    ],
                  ),
                  TextButton(
                    onPressed: controller.goToForgotPassword,
                    child: Text(
                      'Forgot Password',
                      style: AppStyles.bodyMedium.copyWith(
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: 'Login',
                onPressed: controller.login,
              ),
              const SizedBox(height: 30),
              _buildDivider(),
              const SizedBox(height: 30),
              _buildGoogleButton(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: AppStyles.bodyMedium),
                  GestureDetector(
                    onTap: controller.goToSignup,
                    child: Text(
                      'Sign Up',
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
      onPressed: controller.loginWithGoogle,
      isOutlined: true,
      icon: Image.network(
        'https://cdn1.iconfinder.com/data/icons/google_jfk_icons_by_verexis/128/google.png',
        height: 24,
      ),
    );
  }
}
