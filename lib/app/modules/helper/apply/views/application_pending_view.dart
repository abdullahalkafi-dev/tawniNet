import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class ApplicationPendingView extends GetView<ApplyHelperController> {
  const ApplicationPendingView({super.key});

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
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Application Pending',
                style: AppStyles.h2.copyWith(
                  fontSize: 26,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for applying to be a Helper! Our team is currently reviewing your profile and documents.',
                style: AppStyles.bodyMedium.copyWith(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Text(
                  'This process usually takes 24-48 hours. We\'ll notify you via email as soon as there\'s an update.',
                  style: AppStyles.bodyMedium.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification Documents',
                            style: AppStyles.bodyLarge.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Under Review',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    'Your data is stored securely during review.',
                    style: AppStyles.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const Spacer(flex: 2),
              CustomButton(
                text: 'Log out',
                onPressed: controller.logout,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
