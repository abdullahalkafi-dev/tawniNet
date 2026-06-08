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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'My Job',
            style: AppStyles.h1.copyWith(fontSize: 24, color: const Color(0xFF1F2A37)),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Active Job'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJobList(controller.activeJobs, 'active'),
            _buildJobList(controller.completedJobs, 'completed'),
            _buildJobList(controller.cancelledJobs, 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildJobList(List jobs, String type) {
    return Obx(() {
      if (jobs.isEmpty) {
        return const Center(child: Text('No jobs found'));
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
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
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.person, color: Colors.grey),
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
                              style: AppStyles.h2.copyWith(fontSize: 16),
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  job['location'] ?? '',
                                  style: AppStyles.bodyMedium.copyWith(fontSize: 13),
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
                            'View',
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
