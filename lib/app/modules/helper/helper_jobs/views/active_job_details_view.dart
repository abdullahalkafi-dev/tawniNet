import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/job_status_timeline.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActiveJobDetailsView extends StatelessWidget {
  const ActiveJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final job = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'job_details_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobInfoTable(context, job),
            const SizedBox(height: 16),
            _buildJobDescriptionWithPhotos(context, job),
            const SizedBox(height: 16),
            _buildJobStatusTimeline(context, job),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.blueGrey.withOpacity(0.15)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Waiting for the client to confirm service is complete.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showCancelDialog(context, job),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'booking_cancel_booking'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'booking_cancel_warning'.tr,
              style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildInputBar(context, job),
    );
  }

  Widget _buildJobInfoTable(BuildContext context, Map job) {
    final clientName = JobDisplay.personName(job['postedBy'],
        fallback: JobDisplay.safeText(job['clientName']));
    final categoryName = JobDisplay.categoryName(job['category'],
        fallback: JobDisplay.safeText(job['jobType'], fallback: 'Service'));
    final bookingDate = job['date'] != null
        ? AppDateTime.formatDateDisplay(job['date'].toString())
        : AppDateTime.formatDateDisplay(job['bookingDate']?.toString() ?? '');
    final preferredTime = job['startTime'] != null
        ? [
            AppDateTime.formatTime12h(job['startTime']?.toString()),
            if (job['endTime'] != null)
              AppDateTime.formatTime12h(job['endTime']?.toString()),
          ].where((t) => t.isNotEmpty).join(' - ')
        : JobDisplay.safeText(job['preferredTime']);
    final location = JobDisplay.publicAddress(job);
    final budget = job['budget'] != null ? 'MAD ${job['budget']}' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'label_order_by'.tr, clientName),
          _buildInfoRow(context, 'label_job_type'.tr, categoryName),
          _buildInfoRow(context, 'label_booking_date'.tr, bookingDate),
          _buildInfoRow(context, 'label_preferred_time'.tr, preferredTime),
          _buildInfoRow(context, 'label_location'.tr, location),
          _buildInfoRow(context, 'label_budget'.tr, budget),
          if (job['distance'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(job['distance'], style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor)),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionWithPhotos(BuildContext context, Map job) {
    final photos = (job['images'] as List? ?? job['photos'] as List? ?? []);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_job_description'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Text('label_tasks_required'.tr, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            job['description'] ?? '',
            style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5, color: context.textSecondaryColor),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('label_photos'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: List.generate(photos.length.clamp(0, 3), (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photos[index].toString(),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: context.inputFillLight,
                          child: Icon(Icons.image, color: context.textHintColor),
                        );
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobStatusTimeline(BuildContext context, Map job) {
    return JobStatusTimeline(steps: JobTimeline.fromJobMap(job));
  }

  void _showCancelDialog(BuildContext context, Map job) {
    final reasonController = TextEditingController();
    final jobId = (job['id'] ?? job['_id'] ?? '').toString();
    Get.bottomSheet(
      Builder(
        builder: (dialogContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: dialogContext.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dialogContext.borderSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE53935),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'booking_cancel_booking'.tr,
                      style: AppStyles.h2Of(dialogContext).copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'job_cancel_reason_default'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: dialogContext.textSecondaryColor,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: 200,
                      style: TextStyle(color: dialogContext.textPrimaryColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'job_cancel_reason_hint'.tr,
                        hintStyle: AppStyles.bodyMedium.copyWith(
                          color: dialogContext.textHintColor,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: dialogContext.inputFillColor,
                        counterText: "",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dialogContext.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: dialogContext.borderSecondary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'btn_cancel'.tr,
                              style: TextStyle(
                                color: dialogContext.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final reason = reasonController.text.trim();
                              if (reason.length < 3) {
                                AppFeedback.error(
                                  'Please enter a reason (at least 3 characters).',
                                  title: 'Reason required',
                                );
                                return;
                              }
                              Get.back();
                              final controller = Get.find<HelperJobsController>();
                              final ok = await controller.cancelJob(
                                jobId,
                                reason: reason,
                              );
                              if (ok && Get.context != null) {
                                Get.back();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'booking_yes_cancel'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildInputBar(BuildContext context, Map job) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.inputFillLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.image_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                style: TextStyle(color: context.textPrimaryColor),
                decoration: InputDecoration(hintText: 'label_type_message'.tr, hintStyle: TextStyle(color: context.textHintColor), border: InputBorder.none),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
