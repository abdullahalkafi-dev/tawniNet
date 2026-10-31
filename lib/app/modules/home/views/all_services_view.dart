import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class AllServicesView extends StatefulWidget {
  const AllServicesView({super.key});

  @override
  State<AllServicesView> createState() => _AllServicesViewState();
}

class _AllServicesViewState extends State<AllServicesView> {
  final HomeController controller = Get.find<HomeController>();
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'cat_all_services'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
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
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtle),
              ),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: context.textHintColor),
                  hintText: 'cat_search_services'.tr,
                  hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              final query = _search.text.trim().toLowerCase();
              final all = controller.categories.toList();
              if (all.isEmpty && controller.isLoadingCategories.value) {
                return const CategoryGridSkeleton(count: 12);
              }
              if (all.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 40, color: context.textHintColor),
                      const SizedBox(height: 12),
                      Text('post_categories_failed'.tr,
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyMedium.copyWith(color: context.textHintColor)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: controller.fetchCategories,
                        icon: const Icon(Icons.refresh),
                        label: Text('booking_retry'.tr),
                      ),
                    ],
                  ),
                );
              }
              final cats = query.isEmpty
                  ? all
                  : all.where((c) => c.name.toLowerCase().contains(query)).toList();
              if (cats.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text('search_no_results'.tr,
                      style: AppStyles.bodyMedium.copyWith(color: context.textHintColor)),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
