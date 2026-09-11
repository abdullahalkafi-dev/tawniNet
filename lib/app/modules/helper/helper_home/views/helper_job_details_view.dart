import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/core/widgets/job_status_timeline.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/media_downloader.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperJobDetailsView extends GetView<HelperHomeController> {
  const HelperJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final HelperJob job = Get.arguments;

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
            _buildJobInfoCard(context, job),
            const SizedBox(height: 16),
            _buildCustomerInfo(context, job),
            const SizedBox(height: 16),
            _buildJobDescriptionWithPhotos(context, job),
            const SizedBox(height: 16),
            _buildPaymentBreakdown(context, job),
            const SizedBox(height: 16),
            CustomButton(
              text: 'job_accept'.tr,
              onPressed: () => controller.acceptJob(job.id),
            ),
            const SizedBox(height: 16),
            _buildJobStatusTimeline(context, job),
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfoCard(BuildContext context, HelperJob job) {
    final dateStr = job.date != null
        ? AppDateTime.formatDateDisplay(job.date!.toIso8601String())
        : 'Not specified';
    final timeStr = (job.startTime != null && job.startTime!.isNotEmpty)
        ? (job.endTime != null && job.endTime!.isNotEmpty
            ? '${AppDateTime.formatTime12h(job.startTime)} - ${AppDateTime.formatTime12h(job.endTime)}'
            : AppDateTime.formatTime12h(job.startTime))
        : 'Not specified';

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
          Text(job.title, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: context.textSecondaryColor),
              const SizedBox(width: 8),
              Flexible(child: Text(dateStr, style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 16),
              Icon(Icons.access_time_filled, size: 16, color: context.textSecondaryColor),
              const SizedBox(width: 8),
              Flexible(child: Text(timeStr, style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.orange[400]),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  job.address ?? 'Not specified',
                  style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job.category,
            style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(BuildContext context, HelperJob job) {
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
          Text('job_customer_info'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  job.helperImage,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
                      color: context.inputFillLight,
                      child: Icon(Icons.person, color: context.textHintColor),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.helperName,
                      style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      job.category,
                      style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (job.address != null && job.address!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.orange[400]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    job.address!,
                    style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobDescriptionWithPhotos(BuildContext context, HelperJob job) {
    final hasDescription = job.description.isNotEmpty &&
        job.description != 'Professional helper in your area';
    final hasImages = job.images.isNotEmpty;

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
          if (hasDescription) ...[
            Text(
              job.description,
              style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5, color: context.textSecondaryColor),
            ),
          ] else
            Text(
              'No description provided',
              style: AppStyles.bodyMedium.copyWith(
                height: 1.5,
                color: context.textHintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 16),
          Text('label_photos'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          if (hasImages)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: job.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => ImageViewerScreen(
                            imageUrls: job.images,
                            initialIndex: index,
                          ));
                    },
                    onLongPress: () {
                      final url = ApiConstants.resolveImageUrl(job.images[index]) ??
                          job.images[index];
                      final ext = url.split('.').last.split('?').first;
                      MediaDownloader.download(
                        url: url,
                        fileName:
                            'job_image_${DateTime.now().millisecondsSinceEpoch}.$ext',
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        ApiConstants.resolveImageUrl(job.images[index]) ??
                            job.images[index],
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
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: context.inputFillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Center(
                child: Text(
                  'No photos',
                  style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(BuildContext context, HelperJob job) {
    final budget = job.budget ?? 0;
    final platformFee = budget * 0.20;
    final earnings = budget * 0.80;

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
          Text('job_payment_breakdown'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          _buildPaymentRow(
            context,
            'job_payment'.tr,
            'MAD ${budget.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildPaymentRow(
            context,
            'job_platform_fee'.tr,
            '-MAD ${platformFee.toStringAsFixed(2)}',
            isNegative: true,
          ),
          Divider(height: 30, color: context.borderSubtle),
          _buildPaymentRow(
            context,
            'job_your_earnings'.tr,
            'MAD ${earnings.toStringAsFixed(2)}',
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildPaymentRow(
            context,
            'Payment Method',
            job.paymentMethod?.toUpperCase() ?? 'CASH',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.green.withOpacity(0.15) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: context.textPrimaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'job_payment_note'.tr,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(BuildContext context, String label, String value, {bool isNegative = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppStyles.bodyLargeOf(context).copyWith(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppStyles.bodyLargeOf(context).copyWith(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isNegative ? AppColors.error : (isBold ? AppColors.primary : context.textPrimaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildJobStatusTimeline(BuildContext context, HelperJob job) {
    final status = (job.status ?? 'open').toLowerCase();
    final isAssigned = status != 'open' && status != 'pending_payment';
    return JobStatusTimeline(
      steps: JobTimeline.fromStatus(
        status: status,
        submittedAt: null,
        completedAt: null,
        isAssigned: isAssigned,
        escrowCredited: status == 'completed',
        paymentMethod: '',
      ),
    );
  }
}
