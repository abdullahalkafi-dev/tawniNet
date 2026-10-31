import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/notification_badge_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';

class HelperHomeTabView extends GetView<HelperHomeController> {
  const HelperHomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPullToRefresh(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              _buildOffDutyBanner(context),
              const SizedBox(height: 20),
              _buildSearchBar(context),
              const SizedBox(height: 20),
              _buildJobList(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown while the helper is off duty, so an empty list or a refused "Accept" is understood.
  Widget _buildOffDutyBanner(BuildContext context) {
    return Obx(() {
      final available = Get.find<AuthService>().currentUser.value?.isAvailable ?? true;
      if (available) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text('helper_off_duty_banner'.tr, style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Get.find<AuthService>().setAvailability(true);
                } catch (e) {
                  AppFeedback.error(AppSnackbar.extractErrorMessage(e));
                }
              },
              child: Text('helper_go_on_duty'.tr),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Obx(() {
          final user = Get.find<AuthService>().currentUser.value;
          return AppAvatar(url: user?.avatar, name: user?.name ?? '', size: 60);
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final user = Get.find<AuthService>().currentUser.value;
                return Text(
                  user?.name ?? 'ui_helper'.tr,
                  style: AppStyles.h2Of(context).copyWith(fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              Obx(() {
                final user = Get.find<AuthService>().currentUser.value;
                return Text(
                  user?.address ?? 'label_no_location'.tr,
                  style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () async {
            controller.onNotificationTap();
            if (Get.isRegistered<NotificationBadgeController>()) {
              await Get.find<NotificationBadgeController>().refresh();
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 24),
              ),
              PositionedDirectional(
                end: -4,
                top: -4,
                child: Obx(() {
                  final count = Get.isRegistered<NotificationBadgeController>()
                      ? Get.find<NotificationBadgeController>().unread.value
                      : 0;
                  if (count <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        style: GoogleFonts.inter(fontSize: 15, color: context.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'helper_search_jobs'.tr,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: context.textHintColor,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: context.inputFillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: context.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: context.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          prefixIcon: Icon(Icons.search, color: context.textHintColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildJobList(BuildContext context) {
    return Obx(() {
      if (!controller.hasLoadedOnce.value && !controller.loadFailed.value) {
        return Shimmer(
          child: Column(
            children: List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: JobCardSkeleton(),
              ),
            ),
          ),
        );
      }

      if (controller.loadFailed.value && controller.nearbyJobs.isEmpty) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 400),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 56, color: context.textHintColor),
                const SizedBox(height: 12),
                Text(
                  'ui_could_not_load_jobs_pull_down_to'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.fetchNearbyJobs,
                  icon: const Icon(Icons.refresh),
                  label: Text('booking_retry'.tr),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.filteredJobs.isEmpty) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 400),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 60, color: context.textHintColor),
                  const SizedBox(height: 16),
                  Text(
                    'ui_no_nearby_jobs_found'.tr,
                    style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ui_pull_down_to_refresh'.tr,
                    style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        children: controller.filteredJobs.map((job) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(url: job.helperImage, name: job.helperName, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                          ),
                          Text(
                            [job.helperName, if (job.category.isNotEmpty) job.category].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (job.budget != null)
                      Text(
                        job.price,
                        style: AppStyles.bodyLargeOf(context).copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                if (job.bio != null && job.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    job.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (job.distanceKm != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              job.distance,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (job.distanceKm != null) const SizedBox(width: 8),
                    if (job.address != null && job.address!.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.orange[400],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.address!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.bodyMedium.copyWith(
                                  fontSize: 12,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.onJobDetails(job),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'helper_details_btn'.tr,
                          style: AppStyles.buttonText.copyWith(color: AppColors.primary, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.onJobChat(job),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'btn_chat'.tr,
                          style: AppStyles.buttonText.copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

}
