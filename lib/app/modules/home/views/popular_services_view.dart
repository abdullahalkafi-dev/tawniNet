import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class PopularServicesView extends GetView<HomeController> {
  const PopularServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedFilter = 'label_all'.tr.obs;
    final searchQuery = ''.obs;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'popular_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtle),
              ),
              child: TextField(
                onChanged: (value) => searchQuery.value = value,
                style: TextStyle(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: context.textHintColor),
                  hintText: 'popular_search'.tr,
                  hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Obx(
                () => Row(
                  children: [
                    _buildFilterChip(context, 'label_all'.tr, selectedFilter),
                    _buildFilterChip(context, 'label_cleaning'.tr, selectedFilter),
                    _buildFilterChip(context, 'label_repairing'.tr, selectedFilter),
                    _buildFilterChip(context, 'label_painting'.tr, selectedFilter),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final filteredServices = controller.popularServices.where((
                service,
              ) {
                // Filter by Category
                bool matchesCategory = true;
                if (selectedFilter.value != 'label_all'.tr) {
                  matchesCategory = service.category.toLowerCase().contains(
                    selectedFilter.value.toLowerCase(),
                  );
                }

                // Filter by Search Query
                bool matchesSearch = true;
                if (searchQuery.value.isNotEmpty) {
                  matchesSearch =
                      service.name.toLowerCase().contains(
                        searchQuery.value.toLowerCase(),
                      ) ||
                      service.category.toLowerCase().contains(
                        searchQuery.value.toLowerCase(),
                      );
                }

                return matchesCategory && matchesSearch;
              }).toList();

              if (filteredServices.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'popular_no_services'.tr,
                      style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredServices.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildServiceCard(context, filteredServices[index]);
                },
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, RxString selectedFilter) {
    bool isSelected = selectedFilter.value == label;
    return GestureDetector(
      onTap: () => selectedFilter.value = label,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (context.isDarkMode ? AppColors.darkBorder : const Color(0xFF5AB9A7).withOpacity(0.5)),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            color: isSelected
                ? Colors.white
                : (context.isDarkMode ? AppColors.darkTextPrimary : const Color(0xFF5AB9A7)),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, PopularService service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  service.image,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: context.inputFillLight,
                      padding: const EdgeInsets.all(12),
                      child: SvgPicture.asset(
                        'assets/svgs/profile_icon.svg',
                        colorFilter: ColorFilter.mode(
                          context.textHintColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.name,
                          style: AppStyles.bodyLargeOf(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? const Color(0xFF1E3A8A).withOpacity(0.3)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.rating}(${service.reviews})',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: context.isDarkMode ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          service.category,
                          style: AppStyles.bodyMedium.copyWith(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            service.distance,
                            style: AppStyles.bodyMedium.copyWith(
                              fontSize: 12,
                              color: context.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: Colors.grey)),
                        Text(
                          '${formatMoney(service.pricePerHour)}/hr',
                          style: AppStyles.bodyLargeOf(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => controller.onViewProfile(service.id),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide.none,
                      backgroundColor: context.isDarkMode
                          ? AppColors.primary.withOpacity(0.12)
                          : const Color(0xFFF2FAF8),
                    ),
                    child: Text(
                      'btn_view_profile'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.isDarkMode ? AppColors.primary : const Color(0xFF5AB9A7),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => controller.onChatWithHelper(service.id),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'btn_chat'.tr,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
