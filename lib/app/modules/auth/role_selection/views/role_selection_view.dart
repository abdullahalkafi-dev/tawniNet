import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/role_selection_controller.dart';
import '../../../../core/values/app_assets.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';

class RoleSelectionView extends GetView<RoleSelectionController> {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset(AppAssets.selectRole, height: 300),
              const SizedBox(height: 40),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppStyles.h2.copyWith(fontSize: 32, color: Colors.black),
                  children: [
                    const TextSpan(text: 'Select '),
                    TextSpan(
                      text: 'Your Role',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose one from these options.',
                style: AppStyles.bodyMedium.copyWith(fontSize: 16),
              ),
              const Spacer(),
              CustomButton(
                text: 'User (Client)',
                onPressed: controller.selectUser,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Helper (Worker)',
                onPressed: controller.selectHelper,
                isOutlined: true,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
