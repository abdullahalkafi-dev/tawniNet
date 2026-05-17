import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class CategoriesSection extends GetView<HomeController> {
  const CategoriesSection({super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: AppStyles.h2.copyWith(
                fontSize: 18,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: controller.onViewAllCategories,
              child: Text(
                'View All',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // 4 items per row, 12px gap between items horizontally
            final double gap = 12.0;
            final double itemWidth = (constraints.maxWidth - (gap * 3)) / 4;
            
            return Obx(
              () => Wrap(
                spacing: gap,
                runSpacing: 20.0, // Vertical gap between rows
                children: controller.categories.map((cat) {
                  return GestureDetector(
                    onTap: () => controller.onCategorySelected(cat),
                    child: SizedBox(
                      width: itemWidth,
                      child: Column(
                        children: [
                          Container(
                            height: itemWidth, // Make it a square container
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
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
                              width: itemWidth * 0.65, // Inner circle size proportional to outer square
                              height: itemWidth * 0.65,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF0FDF8), // Light cyan/teal circular background
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
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w500,
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
        ),
      ],
    );
  }
}
