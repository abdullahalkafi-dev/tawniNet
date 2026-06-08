import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class ApplicationRejectedView extends GetView<ApplyHelperController> {
  const ApplicationRejectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 50,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Application Status',
                style: AppStyles.h1.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                'NOT APPROVED',
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'We\'re sorry, but your application couldn\'t be approved at this time.',
                style: AppStyles.bodyMedium.copyWith(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REASON FOR DECISION',
                      style: AppStyles.bodyLarge.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The provided ID document was blurry or unreadable. The provided ID document was blurry or unreadable.',
                      style: AppStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              CustomButton(
                text: 'Update & Re-apply',
                onPressed: controller.updateAndReapply,
              ),
              const SizedBox(height: 16),
              Text(
                'You can re-submit your application as many times as needed after fixing the issues.',
                style: AppStyles.bodyMedium.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
