import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/core/widgets/helper_list_card.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class NearbyHelpersView extends GetView<HomeController> {
  const NearbyHelpersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'home_nearby_helpers'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: AppPullToRefresh(
        onRefresh: controller.fetchNearbyHelpers,
        child: Obx(() {
          final helpers = controller.nearbyJobs;
          if (helpers.isEmpty && controller.isLoadingHelpers.value) {
            return SkeletonList(
              count: 5,
              itemBuilder: (_, __) => const HelperCardSkeleton(),
            );
          }
          if (helpers.isEmpty) {
            return ListView(
              primary: false,
              physics: AppAlwaysScrollPhysics,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Icon(
                  controller.helpersFailed.value ? Icons.cloud_off_outlined : Icons.search_off,
                  size: 56,
                  color: context.textHintColor,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    controller.helpersFailed.value
                        ? 'ui_could_not_load_helpers'.tr
                        : 'ui_no_helpers_nearby'.tr,
                    style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: helpers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) => HelperListCard(
              job: helpers[index],
              onTap: () => controller.onJobSelected(helpers[index]),
              onChat: () => controller.onChatWithHelper(helpers[index].id),
            ),
          );
        }),
      ),
    );
  }
}
