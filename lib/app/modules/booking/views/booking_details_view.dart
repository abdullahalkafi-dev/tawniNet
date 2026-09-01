import 'package:awnneaapp/app/core/values/app_colors.dart' show AppColors;
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../../../data/models/booking_model.dart';

class BookingDetailsView extends GetView<BookingController> {
  const BookingDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final Booking booking = Get.arguments;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'booking_my_bookings'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerCard(context, booking),
            const SizedBox(height: 24),
            _buildJobDetailRow(context, 'label_job_type'.tr, booking.jobType),
            _buildJobDetailRow(context, 'label_booking_date'.tr, booking.date),
            _buildJobDetailRow(context, 'label_preferred_time'.tr, booking.time),
            _buildJobDetailRow(context, 'label_location'.tr, booking.location),
            _buildJobDetailRow(context, 'label_budget'.tr, formatMoney(booking.budget)),
            const SizedBox(height: 24),
            _buildJobDescription(context, booking),
            const SizedBox(height: 24),
            _buildJobStatusTimeline(context, booking),
            const SizedBox(height: 40),
            if (booking.status == BookingStatus.inProgress) ...[
              _buildActionButton('booking_confirm_rejection'.tr, AppColors.primary, () {}),
              const SizedBox(height: 16),
              _buildActionButton(
                'booking_cancel_booking'.tr,
                Colors.white,
                () => _showCancelDialog(context),
                isOutlined: true,
              ),
            ] else if (booking.status == BookingStatus.completed) ...[
              _buildActionButton('btn_review'.tr, AppColors.primary, () {}),
            ],
            const SizedBox(height: 20),
            Center(
              child: Text(
                'booking_cancel_warning'.tr,
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  color: context.textHintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, Booking booking) {
    return Container(
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
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(booking.workerImage),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.workerName,
                  style: AppStyles.h2Of(context).copyWith(fontSize: 18),
                ),
                Text(
                  booking.category,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatusBadge(booking.status),
                    const Spacer(),
                    _buildChatButton(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    String text = status == BookingStatus.inProgress
        ? 'booking_inprogress'.tr
        : 'booking_completed'.tr;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'btn_chat'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJobDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
          ),
          Text(
            value,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_job_description'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'label_tasks_required'.tr,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            booking.description,
            style: AppStyles.bodyMediumOf(context).copyWith(
              color: context.textSecondaryColor,
              height: 1.5,
            ),
          ),
          if (booking.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'label_photos'.tr,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: booking.photos
                  .map((url) => _buildPhotoThumb(url))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildJobStatusTimeline(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_job_status'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          _buildTimelineItem(
            context,
            'status_submitted'.tr,
            'March 10, 2024 at 2:30 PM',
            true,
            true,
          ),
          _buildTimelineItem(
            context,
            'status_worker_matched'.tr,
            'March 11, 2024 at 9:15 AM',
            true,
            true,
          ),
          _buildTimelineItem(
            context,
            'status_in_progress'.tr,
            'Started March 15, 2024 at 10:00 AM',
            booking.status != BookingStatus.inProgress,
            booking.status == BookingStatus.inProgress,
          ),
          _buildTimelineItem(context, 'status_completed'.tr, 'Pending', false, false),
          _buildTimelineItem(
            context,
            'status_payment_processed'.tr,
            'Pending',
            false,
            false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    String title,
    String time,
    bool isCompleted,
    bool isInProgress, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primary.withOpacity(0.5)
                    : (isInProgress
                          ? AppColors.primary.withOpacity(0.5)
                          : (context.isDarkMode ? AppColors.darkBorder : Colors.grey[200])),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : (isInProgress ? Icons.circle : Icons.circle),
                color: isCompleted
                    ? Colors.white
                    : (isInProgress ? Colors.white : context.textHintColor),
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.primary.withOpacity(0.5)
                    : (context.isDarkMode ? AppColors.darkBorder : Colors.grey[200]),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted || isInProgress
                      ? context.textPrimaryColor
                      : context.textHintColor,
                ),
              ),
              Text(
                time,
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: context.textHintColor,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text('booking_cancel_booking'.tr, style: AppStyles.h1Of(context).copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            Text(
              'booking_cancel_question'.tr,
              style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.isDarkMode
                          ? AppColors.primary.withOpacity(0.15)
                          : const Color(0xFFE0F7F6),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('btn_cancel'.tr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar('booking_success'.tr, 'booking_cancel_success'.tr);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('booking_yes_cancel'.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
