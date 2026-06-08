import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CompletedJobDetailsView extends StatelessWidget {
  const CompletedJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final job = Get.arguments as Map;

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
          'My Job',
          style: AppStyles.h1.copyWith(fontSize: 20, color: Colors.black),
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
                'Great job! You earned \$${job['earnedAmount'] ?? 88} from this order.',
                style: AppStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            _buildJobInfoTable(job),
            const SizedBox(height: 16),
            _buildJobDescription(job),
            const SizedBox(height: 16),
            _buildPhotos(job),
            const SizedBox(height: 16),
            _buildJobStatusTimeline(),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Review',
              onPressed: () => Get.toNamed(Routes.rateClient, arguments: job),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  Widget _buildJobInfoTable(Map job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Order By', job['orderBy'] ?? job['clientName']),
          _buildInfoRow('Job Type', job['jobType']),
          _buildInfoRow('Booking Date', job['bookingDate']),
          _buildInfoRow('Preferred Time', job['preferredTime']),
          _buildInfoRow('Location', job['location']),
          _buildInfoRow('Budget', 'MAD ${job['budget']}'),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(job['distance'] ?? '', style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildJobDescription(Map job) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Description', style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Text('Tasks Required:', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(job['description'] ?? '', style: AppStyles.bodyMedium.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPhotos(Map job) {
    final photos = job['photos'] as List? ?? [];
    if (photos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photos', style: AppStyles.h2.copyWith(fontSize: 16)),
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
                    return Container(width: 100, height: 100, color: const Color(0xFFF3F4F6));
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildJobStatusTimeline() {
    final steps = [
      {'label': 'Job Submitted', 'date': 'March 10, 2024 at 2:30 PM', 'completed': true},
      {'label': 'Worker Matched', 'date': 'March 11, 2024 at 9:15 AM', 'completed': true},
      {'label': 'In Progress', 'date': 'Started March 15, 2024 at 10:00 AM', 'completed': true},
      {'label': 'Completed', 'date': 'March 11, 2024 at 9:15 AM', 'completed': true},
      {'label': 'Payment Processed', 'date': 'Pending', 'completed': false},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Status', style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final step = entry.value;
            final isLast = entry.key == steps.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (step['completed'] as bool) ? AppColors.primary : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: (step['completed'] as bool)
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    if (!isLast) Container(width: 2, height: 30, color: const Color(0xFFE5E7EB)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label'] as String,
                        style: AppStyles.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: (step['completed'] as bool) ? Colors.black : AppColors.textHint,
                        ),
                      ),
                      Text(step['date'] as String, style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.textHint)),
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.image_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message...', border: InputBorder.none))),
            IconButton(icon: const Icon(Icons.send, color: AppColors.primary), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
