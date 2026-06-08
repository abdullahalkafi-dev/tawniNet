import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperCancelDetailsView extends StatelessWidget {
  const HelperCancelDetailsView({super.key});

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
          'Cancel Details',
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: AppColors.error, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Job Cancelled',
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This job was cancelled on ${job['cancelledDate'] ?? 'March 12, 2026'}',
                    style: AppStyles.bodyMedium.copyWith(color: AppColors.error, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.network(
                    job['clientImage'] ?? 'https://i.pravatar.cc/150?u=default',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 50,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.person, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['clientName'] ?? '', style: AppStyles.h2.copyWith(fontSize: 16)),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(job['location'] ?? '', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard('Cancellation Details', [
              _buildDetailRow('Cancelled by', job['cancelledBy'] ?? ''),
              const SizedBox(height: 8),
              Text('Reason for cancellation', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                job['reason'] ?? '',
                style: AppStyles.bodyLarge.copyWith(color: AppColors.error, fontSize: 14),
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Job Information', [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Sunday, Feb 11, 2026', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_filled, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('10:00 AM - 12:00 PM', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Service Fee MAD ${job['serviceFee'] ?? 85}', style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Service Description', [
              Text(
                job['description'] ?? 'Lorem ipsum dolor sit amet consectetur...',
                style: AppStyles.bodyMedium.copyWith(height: 1.5),
              ),
            ]),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Contact Support',
              onPressed: () => Get.toNamed(Routes.customerService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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
          Text(title, style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppStyles.bodyMedium.copyWith(fontSize: 14)),
        Text(value, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
