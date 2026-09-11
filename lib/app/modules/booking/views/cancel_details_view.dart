import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../../../data/models/booking_model.dart';

class CancelDetailsView extends GetView<BookingController> {
  const CancelDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final Booking? booking = args is Booking ? args : null;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'cancel_details_title'.tr,
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Booking not found. Go back and try again.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'cancel_details_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCancelBanner(context, booking),
            const SizedBox(height: 20),
            _buildWorkerMiniCard(context, booking),
            const SizedBox(height: 24),
            _buildCancellationReason(context, booking),
            const SizedBox(height: 24),
            _buildRefundStatus(context, booking),
            const SizedBox(height: 24),
            _buildJobInfo(context, booking),
            const SizedBox(height: 24),
            _buildServiceDescription(context, booking),
            const SizedBox(height: 40),
            _buildContactSupportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelBanner(BuildContext context, Booking booking) {
    final date = booking.cancelledAt.isNotEmpty
        ? AppDateTime.formatDateDisplay(booking.cancelledAt)
        : booking.date;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.red.withOpacity(0.15)
            : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Colors.red, width: 4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cancel_job_cancelled'.tr,
                  style: AppStyles.bodyLarge.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date.isEmpty
                      ? 'cancel_job_cancelled'.tr
                      : '${'cancel_job_cancelled_on'.tr} $date',
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.red[300],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundStatus(BuildContext context, Booking booking) {
    final isOnline = booking.paymentMethod.toLowerCase() == 'online';
    final refund = booking.refundStatus.toLowerCase();

    Color color;
    IconData icon;
    String title;
    String body;

    if (!isOnline) {
      color = AppColors.primary;
      icon = Icons.account_balance_wallet_outlined;
      title = 'Cash job';
      body =
          'No online charge to refund. Helper commission is returned to their wallet when applicable.';
    } else if (refund == 'refunded') {
      color = const Color(0xFF0F766E);
      icon = Icons.check_circle_outline;
      title = 'Payment refunded';
      body = booking.refundReference.isNotEmpty
          ? 'Refunded to your original payment method.\nRef: ${booking.refundReference}'
          : 'Refunded to your original payment method.';
    } else if (refund == 'failed') {
      color = Colors.orange.shade800;
      icon = Icons.error_outline;
      title = 'Refund needs attention';
      body =
          'Automatic refund did not complete. Contact support with booking ID ${booking.id}.';
    } else if (refund == 'pending') {
      color = Colors.blueGrey;
      icon = Icons.hourglass_empty;
      title = 'Refund processing';
      body = 'Your refund is being processed.';
    } else {
      color = context.textSecondaryColor;
      icon = Icons.info_outline;
      title = 'No charge to refund';
      body = booking.budget > 0
          ? 'This job was cancelled before payment completed (${formatMoney(booking.budget)}).'
          : 'This job was cancelled before any payment.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerMiniCard(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final resolved =
                  ApiConstants.resolveImageUrl(booking.workerImage);
              final hasPhoto = resolved != null && resolved.isNotEmpty;
              return CircleAvatar(
                radius: 30,
                backgroundColor: Colors.red[100],
                backgroundImage: hasPhoto ? NetworkImage(resolved) : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, color: Colors.red),
              );
            },
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
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.location,
                        style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationReason(BuildContext context, Booking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cancel_cancellation_details'.tr,
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            'cancel_cancelled_by'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
          Text(
            booking.workerUserId.isEmpty
                ? 'You'
                : booking.workerName,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'cancel_reason'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
          Text(
            (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty)
                ? booking.cancellationReason!
                : 'cancel_reason_default'.tr,
            style: AppStyles.bodyLarge.copyWith(
              color: Colors.red[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo(BuildContext context, Booking booking) {
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
          Text('cancel_job_info'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            Icons.calendar_today,
            booking.date.isEmpty ? '—' : booking.date,
          ),
          _buildInfoRow(
            context,
            Icons.access_time,
            booking.time.isEmpty ? 'Flexible' : booking.time,
          ),
          _buildInfoRow(
            context,
            Icons.monetization_on_outlined,
            formatMoney(booking.budget),
          ),
          if (booking.location.isNotEmpty)
            _buildInfoRow(context, Icons.location_on_outlined, booking.location),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: context.textPrimaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDescription(BuildContext context, Booking booking) {
    final desc = booking.description.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('cancel_service_description'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          desc.isEmpty ? 'No description provided.' : desc,
          style: AppStyles.bodyMediumOf(context).copyWith(
            color: context.textSecondaryColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSupportButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          try {
            Get.toNamed(Routes.supportTicketList);
          } catch (_) {
            AppFeedback.error('Support is unavailable right now.');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          'cancel_contact_support'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
