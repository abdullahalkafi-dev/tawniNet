import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';

class LocationAllowView extends GetView<LocationController> {
  const LocationAllowView({super.key});

  bool get _isHelper {
    try {
      return Get.find<RoleService>().isHelper;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isHelper ? 'location_find_jobs'.tr : 'location_find_helpers'.tr,
                style: AppStyles.h1Of(context).copyWith(fontSize: 26),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _isHelper
                    ? 'location_jobs_desc'.tr
                    : 'location_helpers_desc'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              Obx(() => CustomButton(
                text: controller.isGettingLocation.value
                    ? 'location_getting'.tr
                    : 'location_allow'.tr,
                onPressed: controller.isGettingLocation.value
                    ? () {}
                    : controller.onAllowLocation,
                icon: controller.isGettingLocation.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              )),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: controller.onEnterManually,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'location_manual'.tr,
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
