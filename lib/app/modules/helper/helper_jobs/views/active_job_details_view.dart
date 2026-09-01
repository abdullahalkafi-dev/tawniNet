import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActiveJobDetailsView extends StatelessWidget {
  const ActiveJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final job = Get.arguments as Map;

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
            _buildJobStatusTimeline(context),
            const SizedBox(height: 24),
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
          _buildInfoRow(context, 'label_order_by'.tr, job['orderBy'] ?? job['clientName'] ?? ''),
          _buildInfoRow(context, 'label_job_type'.tr, job['jobType'] ?? ''),
          _buildInfoRow(context, 'label_booking_date'.tr, job['bookingDate'] ?? ''),
          _buildInfoRow(context, 'label_preferred_time'.tr, job['preferredTime'] ?? ''),
          _buildInfoRow(context, 'label_location'.tr, job['location'] ?? ''),
          _buildInfoRow(context, 'label_budget'.tr, 'MAD ${job['budget'] ?? ''}'),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor)),
          Text(value, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionWithPhotos(BuildContext context, Map job) {
    final photos = job['photos'] as List? ?? [];
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
                      photos[index],
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

  Widget _buildJobStatusTimeline(BuildContext context) {
    final steps = [
      {'label': 'status_submitted'.tr, 'date': 'March 10, 2024 at 2:30 PM', 'completed': true},
      {'label': 'status_worker_matched'.tr, 'date': 'March 11, 2024 at 9:15 AM', 'completed': true},
      {'label': 'status_in_progress'.tr, 'date': 'Started March 15, 2024 at 10:00 AM', 'completed': true, 'active': true},
      {'label': 'status_completed'.tr, 'date': 'Pending', 'completed': false},
      {'label': 'status_payment_processed'.tr, 'date': 'Pending', 'completed': false},
    ];

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
          Text('label_job_status'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final step = entry.value;
            final isLast = entry.key == steps.length - 1;
            final isActive = step['active'] == true;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (step['completed'] as bool)
                            ? (isActive ? AppColors.primary : AppColors.primary)
                            : (context.isDarkMode ? AppColors.darkBorder : const Color(0xFFE5E7EB)),
                        shape: BoxShape.circle,
                      ),
                      child: (step['completed'] as bool)
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    if (!isLast)
                      Container(width: 2, height: 30, color: (context.isDarkMode ? AppColors.darkBorder : const Color(0xFFE5E7EB))),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label'] as String,
                        style: AppStyles.bodyLargeOf(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: (step['completed'] as bool) ? context.textPrimaryColor : context.textHintColor,
                        ),
                      ),
                      Text(
                        step['date'] as String,
                        style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
                      ),
                      SizedBox(height: isLast ? 0 : 12),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Map job) {
    final reasonController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('job_cancel_reason'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'job_cancel_reason_default'.tr,
              style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text('job_cancel_reason'.tr, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(color: context.textPrimaryColor),
              decoration: InputDecoration(
                hintText: 'job_cancel_reason_hint'.tr,
                hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                filled: true,
                fillColor: context.inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderSubtle),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('btn_cancel'.tr, style: AppStyles.buttonText.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('btn_confirm'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
