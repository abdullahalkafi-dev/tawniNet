import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class CategoriesSection extends GetView<HomeController> {
  const CategoriesSection({super.key});

  String _getCategoryFallback(String name) {
    switch (name) {
      case 'Carrying':
        return 'assets/svgs/carrying_icon.svg';
      case 'Cleaning':
        return 'assets/svgs/cleaning_icon.svg';
      case 'Electrician':
        return 'assets/svgs/electrician_icon.svg';
      case 'Barber':
        return 'assets/svgs/barber_icon.svg';
      case 'Floor':
        return 'assets/svgs/floor_icon.svg';
      case 'Shifting':
        return 'assets/svgs/shifting2_icon.svg';
      case 'Garden':
        return 'assets/svgs/garden_icon.svg';
      case 'Moving':
        return 'assets/svgs/shifting_icon.svg';
      default:
        return 'assets/svgs/cleaning_icon.svg';
    }
  }

  Widget _buildCategoryIcon(String? iconUrl, String name, double size) {
    if (iconUrl != null && iconUrl.isNotEmpty) {
      return SvgPicture.network(
        iconUrl,
        width: size,
        height: size,
        placeholderBuilder: (context) => Icon(
          Icons.category_outlined,
          size: size,
          color: AppColors.primary,
        ),
        errorBuilder: (context, error, stackTrace) {
          // Fallback to local asset
          return SvgPicture.asset(
            _getCategoryFallback(name),
            width: size,
            height: size,
          );
        },
      );
    }
    return SvgPicture.asset(
      _getCategoryFallback(name),
      width: size,
      height: size,
    );
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
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 18,
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
            final double gap = 12.0;
            final double itemWidth = (constraints.maxWidth - (gap * 3)) / 4;

            return Obx(
              () => Wrap(
                spacing: gap,
                runSpacing: 20.0,
                children: controller.categories.map((cat) {
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
                                color: context.isDarkMode
                                    ? AppColors.primary.withOpacity(0.12)
                                    : const Color(0xFFF0FDF8),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: _buildCategoryIcon(
                                cat.resolvedIconUrl,
                                cat.name,
                                24,
                              ),
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
