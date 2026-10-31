import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/helper_form_fields.dart';
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
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final error = controller.searchError.value;
                if (error != null) {
                  return Column(
                    children: [
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: AppStyles.bodyMedium.copyWith(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: controller.retrySearch,
                        icon: const Icon(Icons.refresh),
                        label: Text('booking_retry'.tr),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: _cityList(context)),
                    ],
                  );
                }
                if (controller.searchResults.isEmpty) {
                  return Column(
                    children: [
                      if (controller.searchedEmpty.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'location_no_results'.tr,
                            textAlign: TextAlign.center,
                            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                          ),
                        ),
                      Expanded(child: _cityList(context)),
                    ],
                  );
                }
                return ListView.separated(
                  itemCount: controller.searchResults.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: context.borderSubtle),
                  itemBuilder: (context, index) {
                    final result = controller.searchResults[index];
                    final displayName = result['displayName'] as String? ?? '';
                    return InkWell(
                      onTap: () => controller.selectLocation(result),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayName,
                                style: AppStyles.bodyLargeOf(context).copyWith(
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Always-available fallback: pick a city, no address search needed.
  Widget _cityList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'location_pick_city'.tr,
          style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() => AbsorbPointer(
                absorbing: controller.isSavingCity.value,
                child: Opacity(
                  opacity: controller.isSavingCity.value ? 0.5 : 1,
                  child: ListView(
                    children: [
                      for (final city in kMoroccanCities)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_city_outlined, color: AppColors.primary, size: 20),
                          title: Text(city),
                          onTap: () => controller.selectCity(city),
                        ),
                    ],
                  ),
                ),
              )),
        ),
      ],
    );
  }
}
