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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Cancel Details',
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCancelBanner(booking.date),
            const SizedBox(height: 20),
            _buildWorkerMiniCard(booking),
            const SizedBox(height: 24),
            _buildCancellationReason(booking),
            const SizedBox(height: 24),
            _buildJobInfo(booking),
            const SizedBox(height: 24),
            _buildServiceDescription(booking),
            const SizedBox(height: 40),
            _buildContactSupportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelBanner(String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
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
                  'Job Cancelled',
                  style: AppStyles.bodyLarge.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'This job was cancelled on $date',
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

  Widget _buildWorkerMiniCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
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
                  style: AppStyles.h2.copyWith(fontSize: 18),
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
                      style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
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

  Widget _buildCancellationReason(Booking booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation Details',
            style: AppStyles.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Text(
            'Cancelled by',
            style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          Text(
            booking.workerName,
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Reason for cancellation',
            style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
          Text(
            'Emergency came up, unable to fulfill the appointment',
            style: AppStyles.bodyLarge.copyWith(
              color: Colors.red[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfo(Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Information', style: AppStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, 'Sunday, Feb 11, 2026'),
          _buildInfoRow(Icons.access_time, '10:00 AM - 12:00 PM'),
          _buildInfoRow(Icons.monetization_on_outlined, 'Service Fee MAD 85'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1F2A37), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppStyles.bodyLarge.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDescription(Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Description', style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        Text(
          'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum. Lorem quam vitae mus metus tortor turpis at. Cras accumsan pharetra odio euismod metus leo neque duis. more',
          style: AppStyles.bodyMedium.copyWith(
            color: Colors.grey[600],
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
        child: const Text(
          'Contact Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
