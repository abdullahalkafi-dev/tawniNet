import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:awnneaapp/app/modules/home/views/popular_services_view.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:flutter/material.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:get/get.dart';
import '../../../../data/models/home_models.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/helper_trust_widgets.dart';

class PopularServicesSection extends GetView<HomeController> {
  const PopularServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // The chosen category lives in the controller: it survives rebuilds and tab switches.
    final selectedFilter = controller.popularFilter;
    final allLabel = 'label_all'.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'popular_title'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 18,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const PopularServicesView()),
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
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Obx(() {
            // Build filter chips from categories
            final chips = <Widget>[
              _buildFilterChip(context, allLabel, selectedFilter, value: ''),
            ];
            for (final cat in controller.categories) {
              chips.add(_buildFilterChip(context, cat.name, selectedFilter, value: cat.name));
            }
            return Row(children: chips);
          }),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.popularServices.isEmpty && controller.isLoadingHelpers.value) {
            return SkeletonList(
              count: 2,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemBuilder: (_, __) => const HelperCardSkeleton(),
            );
          }

          if (controller.popularServices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'popular_no_services'.tr,
                  style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                ),
              ),
            );
          }

          final filteredServices = controller.popularServices.where((service) {
            if (selectedFilter.value.isEmpty) return true;
            return service.category.toLowerCase() == selectedFilter.value.toLowerCase();
          }).toList();

          if (filteredServices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
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
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildServiceCard(context, filteredServices[index]);
            },
          );
        }),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, RxString selectedFilter,
      {required String value}) {
    bool isSelected = selectedFilter.value == value;
    return GestureDetector(
      onTap: () => selectedFilter.value = value,
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (context.isDarkMode ? AppColors.darkBorder : const Color(0xFF5AB9A7).withValues(alpha: 0.5)),
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
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(url: service.image, name: service.name, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              service.name,
                              style: AppStyles.bodyLargeOf(context).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (service.isVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(compact: true),
                          ],
                          const Spacer(),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
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
                            color: AppColors.primary.withValues(alpha: 0.8),
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
                            ? AppColors.primary.withValues(alpha: 0.12)
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
                      style: TextStyle(
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
