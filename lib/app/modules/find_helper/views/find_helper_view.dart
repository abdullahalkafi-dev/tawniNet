import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart' show AppStyles;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/find_helper_controller.dart';
import '../../home/controllers/home_controller.dart';

class FindHelperView extends GetView<FindHelperController> {
  const FindHelperView({super.key});

  String _getCategorySvg(String id) {
    switch (id) {
      case '1':
        return 'assets/svgs/carrying_icon.svg';
      case '2':
        return 'assets/svgs/cleaning_icon.svg';
      case '3':
        return 'assets/svgs/electrician_icon.svg';
      case '4':
        return 'assets/svgs/barber_icon.svg';
      case '5':
        return 'assets/svgs/floor_icon.svg';
      case '6':
        return 'assets/svgs/shifting2_icon.svg';
      case '7':
        return 'assets/svgs/garden_icon.svg';
      case '8':
        return 'assets/svgs/shifting_icon.svg';
      default:
        return 'assets/svgs/cleaning_icon.svg';
    }
  }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gap = 12.0;
        final double itemWidth = (constraints.maxWidth - (gap * 3)) / 4;
        
        return Obx(
          () => Wrap(
            spacing: gap,
            runSpacing: 20.0,
            children: homeController.categories.map((cat) {
              final index = homeController.categories.indexOf(cat);
              bool isSelected = controller.selectedCategoryIndex.value == index;
              return GestureDetector(
                onTap: () => controller.selectCategory(index),
                child: SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      Container(
                        height: itemWidth,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0FDF8) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: itemWidth * 0.65,
                          height: itemWidth * 0.65,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFF0FDF8),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            _getCategorySvg(cat.id),
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          color: isSelected ? AppColors.primary : const Color(0xFF1F2937),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
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
