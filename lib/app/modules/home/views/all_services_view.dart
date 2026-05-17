import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class AllServicesView extends GetView<HomeController> {
  const AllServicesView({super.key});

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
    // Generate 16 categories for the grid based on the original 8 to match the image
    final allCategories = [
      ...controller.categories,
      ...controller.categories
          .map(
            (c) =>
                Category(id: c.id, name: c.name, icon: c.icon, color: c.color),
          )
          .toList(),
    ];

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
          'All Services',
          style: AppStyles.h2.copyWith(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search Services...',
                  hintStyle: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final double gap = 12.0;
                final double itemWidth = (constraints.maxWidth - (gap * 3)) / 4;

                return Wrap(
                  spacing: gap,
                  runSpacing: 20.0,
                  children: allCategories.map((cat) {
                    return GestureDetector(
                      onTap: () => controller.onCategorySelected(cat),
                      child: SizedBox(
                        width: itemWidth,
                        child: Column(
                          children: [
                            Container(
                              height: itemWidth,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0FDF8),
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
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
