import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../../../data/models/booking_model.dart';

class CancelDetailsView extends GetView<BookingController> {
  const CancelDetailsView({super.key});

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
            _buildCancelBanner(context, booking.date),
            const SizedBox(height: 20),
            _buildWorkerMiniCard(context, booking),
            const SizedBox(height: 24),
            _buildCancellationReason(context, booking),
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

  Widget _buildCancelBanner(BuildContext context, String date) {
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
                  'cancel_job_cancelled_on'.tr + date,
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
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red[100],
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
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking.location,
                      style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
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
            booking.workerName,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'cancel_reason'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
          Text(
            'cancel_reason_default'.tr,
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
          _buildInfoRow(context, Icons.calendar_today, 'Sunday, Feb 11, 2026'),
          _buildInfoRow(context, Icons.access_time, '10:00 AM - 12:00 PM'),
          _buildInfoRow(context, Icons.monetization_on_outlined, 'cancel_service_fee'.tr + '85'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('cancel_service_description'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum. Lorem quam vitae mus metus tortor turpis at. Cras accumsan pharetra odio euismod metus leo neque duis. more',
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
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withOpacity(0.5),
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
