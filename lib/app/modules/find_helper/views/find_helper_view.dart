import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart' show AppStyles;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/find_helper_controller.dart';
import '../../home/controllers/home_controller.dart';

class FindHelperView extends GetView<FindHelperController> {
  const FindHelperView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Find Helpers',
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services Category',
              style: AppStyles.h2.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildCategoryGrid(homeController),
            const SizedBox(height: 24),
            Text('Sort By', style: AppStyles.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            _buildSortOptions(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance', style: AppStyles.h2.copyWith(fontSize: 18)),
                Text(
                  '50km',
                  style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
            _buildDistanceSlider(),
            const SizedBox(height: 24),
            Text('Rating', style: AppStyles.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            _buildRatingBar(),
            const SizedBox(height: 24),
            _buildAvailableNowToggle(),
            const SizedBox(height: 40),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(HomeController homeController) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: homeController.categories.length,
      itemBuilder: (context, index) {
        final cat = homeController.categories[index];
        return Obx(() {
          bool isSelected = controller.selectedCategoryIndex.value == index;
          return GestureDetector(
            onTap: () => controller.selectCategory(index),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[100]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    cat.icon,
                    color: isSelected ? AppColors.primary : cat.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.name,
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: isSelected ? AppColors.primary : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildSortOptions() {
    final options = ['Nearest', 'Highest Rated', 'Lowest Price'];
    return Row(
      children: options.map((opt) {
        return Obx(() {
          bool isSelected = controller.sortBy.value == opt;
          return GestureDetector(
            onTap: () => controller.setSortBy(opt),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[100]!,
                ),
              ),
              child: Text(
                opt,
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: isSelected ? AppColors.primary : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildDistanceSlider() {
    return Obx(
      () => Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey[200],
              thumbColor: Colors.white,
              overlayColor: AppColors.primary.withOpacity(0.2),
              valueIndicatorColor: AppColors.primary,
              valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            ),
            child: Slider(
              value: controller.distanceValue.value,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${controller.distanceValue.value.toInt()}km',
              onChanged: (val) => controller.distanceValue.value = val,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1km', style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
              Text(
                '${controller.distanceValue.value.toInt()}km',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      children: List.generate(5, (index) {
        return Obx(
          () => IconButton(
            icon: Icon(
              index < controller.ratingValue.value
                  ? Icons.star
                  : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
            onPressed: () => controller.ratingValue.value = index + 1.0,
          ),
        );
      }),
    );
  }

  Widget _buildAvailableNowToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Now', style: AppStyles.h2.copyWith(fontSize: 18)),
            Text(
              'Only Show helpers online',
              style: AppStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Obx(
          () => Switch(
            value: controller.isAvailableNow.value,
            onChanged: (val) => controller.isAvailableNow.value = val,
            activeColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: controller.clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear All'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ),
      ],
    );
  }
}
