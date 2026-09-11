import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/find_helper_controller.dart';

class FindHelperView extends GetView<FindHelperController> {
  const FindHelperView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'location_find_helpers'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filters section
          Expanded(
            flex: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'find_category'.tr,
                    style: AppStyles.h2Of(context).copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryChips(context),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('find_distance'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
                      Obx(() => Text(
                        '${controller.distanceValue.value.toInt()}km',
                        style: AppStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      )),
                    ],
                  ),
                  _buildDistanceSlider(context),
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Results section
          Expanded(
            child: _buildResultsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return Obx(() {
      final cats = controller.categories;
      if (cats.isEmpty) return const SizedBox.shrink();

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // "All" chip
            _buildChip(context, 'All', 0),
            ...cats.asMap().entries.map((entry) {
              return _buildChip(context, entry.value.name, entry.key + 1);
            }),
          ],
        ),
      );
    });
  }

  Widget _buildChip(BuildContext context, String label, int index) {
    return Obx(() {
      final isSelected = controller.selectedCategoryIndex.value == index;
      return GestureDetector(
        onTap: () => controller.selectCategory(index),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.borderSecondary,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : context.textPrimaryColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDistanceSlider(BuildContext context) {
    return Obx(() => Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: context.isDarkMode ? AppColors.darkBorder : Colors.grey[200],
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: controller.distanceValue.value,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${controller.distanceValue.value.toInt()}km',
            onChanged: (val) => controller.updateDistance(val),
            onChangeEnd: (_) => controller.applyFiltersInPlace(),
          ),
        ),
      ],
    ));
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: OutlinedButton(
              onPressed: controller.clearFilters,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.borderSecondary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('find_clear_all'.tr, style: TextStyle(color: context.textPrimaryColor)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 45,
            child: ElevatedButton(
              onPressed: () => controller.applyFilters(closeScreen: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('find_apply_filters'.tr),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.helpers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: context.textHintColor),
              const SizedBox(height: 16),
              Text(
                'find_no_helpers'.tr,
                style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                'find_try_adjusting'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(color: context.textHintColor),
              ),
            ],
          ),
        );
      }

      return AppPullToRefresh(
        onRefresh: controller.refreshData,
        child: ListView.separated(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: controller.helpers.length + (controller.isLoadingMore.value ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == controller.helpers.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _buildHelperCard(context, controller.helpers[index]);
          },
        ),
      );
    });
  }

  Widget _buildHelperCard(BuildContext context, HelperJob helper) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              helper.helperImage,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: context.inputFillLight,
                child: Icon(Icons.person, color: context.textHintColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper.helperName,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.primary.withOpacity(0.15)
                            : const Color(0xFFE5F7F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        helper.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.orange[400]),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        helper.distance,
                        style: TextStyle(fontSize: 12, color: context.textHintColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text('btn_chat'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
