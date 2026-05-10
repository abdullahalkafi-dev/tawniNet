import 'package:awnneaapp/app/core/values/app_colors.dart' show AppColors;
import 'package:awnneaapp/app/core/values/app_styles.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'My Bookings',
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerCard(booking),
            const SizedBox(height: 24),
            _buildJobDetailRow('Job Type', booking.jobType),
            _buildJobDetailRow('Booking Date', booking.date),
            _buildJobDetailRow('Preferred Time', booking.time),
            _buildJobDetailRow('Location', booking.location),
            _buildJobDetailRow('Budget', '\$${booking.budget.toInt()}'),
            const SizedBox(height: 24),
            _buildJobDescription(booking),
            const SizedBox(height: 24),
            _buildJobStatusTimeline(booking),
            const SizedBox(height: 40),
            if (booking.status == BookingStatus.inProgress) ...[
              _buildActionButton('Confirm Rejection', AppColors.primary, () {}),
              const SizedBox(height: 16),
              _buildActionButton(
                'Cancel Booking',
                Colors.white,
                () => _showCancelDialog(),
                isOutlined: true,
              ),
            ] else if (booking.status == BookingStatus.completed) ...[
              _buildActionButton('Review', AppColors.primary, () {}),
            ],
            const SizedBox(height: 20),
            Center(
              child: Text(
                'If cancellations happen repeatedly, your account may be temporarily suspended.',
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Booking booking) {
    return Container(
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
                  style: AppStyles.h2.copyWith(fontSize: 18),
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
        ? 'Inprogress'
        : 'Completed';
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
      child: const Text(
        'Chat',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildJobDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppStyles.bodyLarge.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription(Booking booking) {
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
          Text('Job Description', style: AppStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'Tasks Required:',
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            booking.description,
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          if (booking.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Photos',
              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildJobStatusTimeline(Booking booking) {
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
          Text('Job Status', style: AppStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Job Submitted',
            'March 10, 2024 at 2:30 PM',
            true,
            true,
          ),
          _buildTimelineItem(
            'Worker Matched',
            'March 11, 2024 at 9:15 AM',
            true,
            true,
          ),
          _buildTimelineItem(
            'In Progress',
            'Started March 15, 2024 at 10:00 AM',
            booking.status != BookingStatus.inProgress,
            booking.status == BookingStatus.inProgress,
          ),
          _buildTimelineItem('Completed', 'Pending', false, false),
          _buildTimelineItem(
            'Payment Processed',
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
                          : Colors.grey[200]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : (isInProgress ? Icons.circle : Icons.circle),
                color: isCompleted
                    ? Colors.white
                    : (isInProgress ? Colors.white : Colors.grey[400]),
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.grey[200],
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
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isCompleted || isInProgress
                      ? Colors.black
                      : Colors.grey,
                ),
              ),
              Text(
                time,
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: Colors.grey,
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

  void _showCancelDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text('Cancel Booking', style: AppStyles.h1.copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            Text(
              'Are you sure want to cancel your service booking?',
              style: AppStyles.bodyLarge.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0F7F6),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar('Success', 'Booking cancelled successfully');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Yes, Cancel Booking'),
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
