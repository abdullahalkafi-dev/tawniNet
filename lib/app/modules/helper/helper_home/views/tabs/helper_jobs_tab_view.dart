import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
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

  Widget _buildJobList(BuildContext context, List jobs, String type) {
    return Obx(() {
      if (jobs.isEmpty) {
        return Center(child: Text('helper_no_jobs'.tr, style: TextStyle(color: context.textHintColor)));
      }
      return ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: jobs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final job = jobs[index];
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
                      job['clientImage'] ?? '',
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
                              job['clientName'] ?? '',
                              style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.orange[400]),
                                const SizedBox(width: 4),
                                Text(
                                  job['location'] ?? '',
                                  style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildStatusBadge(job['status'] ?? ''),
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
    });
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Inprogress':
        color = const Color(0xFF7CE0C3);
        break;
      case 'Completed':
        color = AppColors.primary;
        break;
      case 'Cancelled':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
