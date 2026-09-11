import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/core/widgets/job_status_timeline.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompletedJobDetailsView extends StatelessWidget {
  const CompletedJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final job = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    final budgetRaw = job['budget'];
    final budget = budgetRaw is num
        ? budgetRaw.toDouble()
        : (double.tryParse(budgetRaw?.toString() ?? '') ?? 0.0);
    final isCash = job['paymentMethod'] == 'cash';
    final earned = (job['earnedAmount'] as num?)?.toDouble() ?? (isCash ? budget : budget * 0.8);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'helper_my_job'.tr,
          style: AppStyles.h1Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'completed_earned'.tr.replaceAll('@amount', formatMoney(earned)),
                style: AppStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            _buildJobInfoTable(context, job),
            const SizedBox(height: 16),
            _buildJobDescription(context, job),
            const SizedBox(height: 16),
            _buildPhotos(context, job),
            const SizedBox(height: 16),
            _buildJobStatusTimeline(context, job),
            const SizedBox(height: 24),
            if (job['hasReviewFromOther'] == true && job['reviewFromOther'] is Map)
              _buildReviewCard(
                context,
                title: 'Client review',
                review: Map<String, dynamic>.from(job['reviewFromOther'] as Map),
              ),
            if (job['hasReviewFromOther'] == true &&
                job['hasMyReview'] != true)
              const SizedBox(height: 12),
            if (job['hasMyReview'] == true && job['myReview'] is Map)
              _buildReviewCard(
                context,
                title: 'Your review',
                review: Map<String, dynamic>.from(job['myReview'] as Map),
              )
            else
              CustomButton(
                text: 'btn_review'.tr,
                onPressed: () => Get.toNamed(Routes.rateClient, arguments: job),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _buildInputBar(context),
    );
  }

  Widget _buildReviewCard(
    BuildContext context, {
    required String title,
    required Map review,
  }) {
    final ratingRaw = review['rating'];
    final rating = (ratingRaw is num
            ? ratingRaw
            : (num.tryParse(ratingRaw?.toString() ?? '') ?? 0))
        .round()
        .clamp(0, 5);
    final comment = (review['comment'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppStyles.h2Of(context).copyWith(fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.verified, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: AppStyles.bodyMediumOf(context).copyWith(height: 1.4),
            ),
          ],
        ],
      ),
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
    final location = JobDisplay.safeLocation(job);
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

  Widget _buildJobDescription(BuildContext context, Map job) {
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
          Text(job['description'] ?? '', style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5, color: context.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildPhotos(BuildContext context, Map job) {
    final photos = (job['images'] as List? ?? job['photos'] as List? ?? []);
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    return Container(width: 100, height: 100, color: context.inputFillLight);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildJobStatusTimeline(BuildContext context, Map job) {
    return JobStatusTimeline(steps: JobTimeline.fromJobMap(job));
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: context.inputFillLight, borderRadius: BorderRadius.circular(12)),
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
            IconButton(icon: const Icon(Icons.send, color: AppColors.primary), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
