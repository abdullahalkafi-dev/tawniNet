import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';

class LocationAllowView extends GetView<LocationController> {
  const LocationAllowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Find Helpers Near You',
                style: AppStyles.h1.copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To connect you with the best barbers, electricians, and plumbers in your neighbourhood, we need access to your device\'s location.',
                style: AppStyles.bodyMedium.copyWith(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              CustomButton(
                text: 'Allow location Access',
                onPressed: controller.onAllowLocation,
                icon: Icon(Icons.send, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: controller.onEnterManually,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Enter Location manually',
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
