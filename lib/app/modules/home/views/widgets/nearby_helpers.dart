import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../nearby_helpers_view.dart';
import 'package:awnneaapp/app/core/widgets/helper_list_card.dart';

class NearbyHelpers extends GetView<HomeController> {
  const NearbyHelpers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'home_nearby_helpers'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 18,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const NearbyHelpersView()),
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
        Obx(() {
          final helpers = controller.nearbyJobs;

          // First load: cards that look like the real ones.
          if (helpers.isEmpty && controller.isLoadingHelpers.value) {
            return SkeletonList(
              count: 3,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemBuilder: (_, __) => const HelperCardSkeleton(),
            );
          }

          if (helpers.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Column(
                children: [
                  Icon(
                    controller.helpersFailed.value ? Icons.cloud_off_outlined : Icons.search_off,
                    color: context.textHintColor,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.helpersFailed.value
                        ? 'ui_could_not_load_helpers'.tr
                        : 'ui_no_helpers_nearby'.tr,
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  ),
                  if (controller.helpersFailed.value)
                    TextButton(
                      onPressed: controller.fetchNearbyHelpers,
                      child: Text('booking_retry'.tr),
                    ),
                ],
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: helpers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return HelperListCard(
                job: helpers[index],
                onTap: () => controller.onJobSelected(helpers[index]),
                onChat: () => controller.onChatWithHelper(helpers[index].id),
              );
            },
          );
        }),
      ],
    );
  }
}
