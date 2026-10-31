import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class CategoriesSection extends GetView<HomeController> {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home_categories'.tr,
              style: AppStyles.h2Of(context).copyWith(fontSize: 18),
            ),
            TextButton(
              onPressed: controller.onViewAllCategories,
              child: Text(
                'home_view_all'.tr,
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
        Obx(() {
          final cats = controller.categories;

          // First load: tiles that look like the real ones.
          if (cats.isEmpty && controller.isLoadingCategories.value) {
            return const CategoryGridSkeleton(count: 8);
          }

          if (cats.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off_outlined, color: context.textHintColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'post_categories_failed'.tr,
                      style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.fetchCategories,
                    child: Text('booking_retry'.tr),
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              const double gap = 12.0;
              final double itemWidth = (constraints.maxWidth - (gap * 3)) / 4;

              return Wrap(
                spacing: gap,
                runSpacing: 20.0,
                children: cats.map((cat) {
                  return GestureDetector(
                    onTap: () => controller.onCategorySelected(cat),
                    child: SizedBox(
                      width: itemWidth,
                      child: Column(
                        children: [
                          Container(
                            height: itemWidth,
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.borderSubtle),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              width: itemWidth * 0.82,
                              height: itemWidth * 0.82,
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : const Color(0xFFF0FDF8),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: CategoryIcon(category: cat, size: 30),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            style: AppStyles.bodyMediumOf(context).copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        }),
      ],
    );
  }
}
