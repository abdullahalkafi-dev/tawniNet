import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_controller.dart';

class ManualLocationView extends GetView<LocationController> {
  const ManualLocationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'location_search_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TextField(
              onChanged: controller.searchLocation,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'location_search_hint'.tr,
                hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                prefixIcon: Icon(Icons.search, color: context.textHintColor),
                filled: true,
                fillColor: context.inputFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: controller.onUseCurrentLocation,
              child: Row(
                children: [
                  const Icon(Icons.send, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'location_use_current'.tr,
                    style: AppStyles.bodyLargeOf(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'location_search_results'.tr,
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isSearching.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: controller.searchResults.map((result) {
                  final displayName = result['displayName'] as String? ?? '';
                  return GestureDetector(
                    onTap: () => controller.selectLocation(result),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayName,
                              style: AppStyles.bodyLargeOf(context).copyWith(
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
