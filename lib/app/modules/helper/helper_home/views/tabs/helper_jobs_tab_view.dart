import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/core/widgets/job_status_badge.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/data/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';

class HelperJobsTabView extends GetView<HelperJobsController> {
  const HelperJobsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'helper_my_job'.tr,
            style: AppStyles.h1Of(context).copyWith(fontSize: 24),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.textHintColor,
            labelStyle: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'helper_active_job'.tr),
              Tab(text: 'helper_completed'.tr),
              Tab(text: 'helper_cancelled'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobList(context, controller.activeJobs, 'active'),
            _buildJobList(context, controller.completedJobs, 'completed'),
            _buildJobList(context, controller.cancelledJobs, 'cancelled'),
          ],
        ),
      ),
    );
  }

  /// Flatten API job map into safe display fields (never pass Maps to Text).
  ({String name, String avatar, String address, BookingStatus status, bool waiting}) _jobDisplay(
      dynamic job) {
    final map = job is Map ? Map<String, dynamic>.from(job) : <String, dynamic>{};

    final postedBy = map['postedBy'];
    String name = '';
    String avatar = '';
    if (postedBy is Map) {
      name = (postedBy['name'] ?? '').toString();
      avatar = (postedBy['avatar'] ?? '').toString();
    }
    name = name.isEmpty ? (map['clientName'] ?? '').toString() : name;
    avatar = avatar.isEmpty ? (map['clientImage'] ?? '').toString() : avatar;

    return (
      name: name.isEmpty ? 'ui_client'.tr : name,
      avatar: avatar,
      // Never show raw GeoJSON coords — city/street only for privacy.
      address: JobDisplay.publicAddress(map),
      status: bookingStatusFromApi((map['status'] ?? '').toString()),
      waiting: map['helperFinishedAt'] != null &&
          map['helperFinishedAt'].toString().isNotEmpty &&
          (map['status'] ?? '') != 'completed',
    );
  }

  Widget _buildJobList(BuildContext context, List jobs, String type) {
    // Keep RefreshIndicator outside Obx so load-state rebuilds don't cancel pull.
    return AppPullToRefresh(
      onRefresh: () => controller.fetchJobs(userInitiated: true),
      child: Obx(() {
        if (!controller.hasLoadedOnce.value && !controller.loadFailed.value && jobs.isEmpty) {
          return SkeletonList(
            count: 4,
            spacing: 16,
            padding: const EdgeInsets.all(20),
            itemBuilder: (_, __) => const HelperCardSkeleton(),
          );
        }

        if (controller.loadFailed.value && jobs.isEmpty) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Icon(Icons.cloud_off_outlined, size: 56, color: context.textHintColor),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'ui_could_not_load_jobs_pull_down_to'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => controller.fetchJobs(userInitiated: true),
                  icon: const Icon(Icons.refresh),
                  label: Text('booking_retry'.tr),
                ),
              ),
            ],
          );
        }

        if (jobs.isEmpty) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Icon(Icons.work_outline, size: 56, color: context.textHintColor),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'helper_no_jobs'.tr,
                  style: TextStyle(color: context.textHintColor),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'ui_pull_down_to_refresh'.tr,
                  style: TextStyle(color: context.textHintColor, fontSize: 12),
                ),
              ),
            ],
          );
        }

        final hasMore = type == 'completed'
            ? controller.completedHasMore.value
            : type == 'cancelled'
                ? controller.cancelledHasMore.value
                : false;

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (hasMore && n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              controller.loadMore(type);
            }
            return false;
          },
          child: ListView.separated(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            padding: const EdgeInsets.all(20),
            itemCount: jobs.length + (hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index >= jobs.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final job = jobs[index];
              final d = _jobDisplay(job);
              return GestureDetector(
                onTap: () => controller.onJobTap(job, type),
                child: Container(
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
                  child: Row(
                    children: [
                      AppAvatar(url: d.avatar, name: d.name, size: 60),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.orange[400]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    d.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppStyles.bodyMedium.copyWith(
                                      fontSize: 13,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                JobStatusBadge(status: d.status, waitingConfirmation: d.waiting),
                                const Spacer(),
                                Text(
                                  'btn_view'.tr,
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
