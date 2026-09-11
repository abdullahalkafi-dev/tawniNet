import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
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
  ({String name, String avatar, String address, String statusLabel, Color statusColor})
      _jobDisplay(dynamic job) {
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

    // Never show raw GeoJSON coords — city/street only for privacy.
    String address = JobDisplay.publicAddress(map);

    final statusRaw = (map['status'] ?? '').toString().toLowerCase();
    String statusLabel;
    Color statusColor;
    switch (statusRaw) {
      case 'in_progress':
      case 'inprogress':
        statusLabel = 'In Progress';
        statusColor = const Color(0xFF7CE0C3);
        break;
      case 'completed':
        statusLabel = 'Completed';
        statusColor = AppColors.primary;
        break;
      case 'cancelled':
        statusLabel = 'Cancelled';
        statusColor = Colors.orange;
        break;
      case 'open':
        statusLabel = 'Open';
        statusColor = Colors.blueGrey;
        break;
      case 'pending_payment':
        statusLabel = 'Unpaid';
        statusColor = Colors.orange.shade700;
        break;
      default:
        statusLabel = statusRaw.isEmpty ? '—' : statusRaw;
        statusColor = Colors.grey;
    }

    return (
      name: name.isEmpty ? 'Client' : name,
      avatar: avatar,
      address: address.isEmpty ? 'No location' : address,
      statusLabel: statusLabel,
      statusColor: statusColor,
    );
  }

  Widget _buildJobList(BuildContext context, List jobs, String type) {
    // Keep RefreshIndicator outside Obx so load-state rebuilds don't cancel pull.
    return AppPullToRefresh(
      onRefresh: () => controller.fetchJobs(userInitiated: true),
      child: Obx(() {
        final isLoading = controller.isLoading.value && jobs.isEmpty;

        if (isLoading) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: const [
              SizedBox(height: 160),
              Center(child: CircularProgressIndicator()),
            ],
          );
        }

        if (jobs.isEmpty) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Center(
                child: Text(
                  'helper_no_jobs'.tr,
                  style: TextStyle(color: context.textHintColor),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Pull down to refresh',
                  style: TextStyle(
                    color: context.textHintColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.separated(
                    primary: false,
                    physics: AppAlwaysScrollPhysics,
                    padding: const EdgeInsets.all(20),
                    itemCount: jobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
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
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  ApiConstants.resolveImageUrl(d.avatar) ?? d.avatar,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: context.inputFillLight,
                                      child: Icon(Icons.person, color: context.textHintColor),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.name,
                                          style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                                        ),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: d.statusColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            d.statusLabel,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Text(
                                        'btn_view'.tr,
                                        style: AppStyles.bodyLarge.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
        );
      }),
    );
  }
}
