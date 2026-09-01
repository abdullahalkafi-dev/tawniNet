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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'cancel_details_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
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
                color: context.isDarkMode
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.error.withOpacity(0.05),
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
                        'cancel_job_cancelled'.tr,
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'cancel_job_cancelled_on'.tr}${job['cancelledDate'] ?? 'March 12, 2026'}',
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
                        color: context.inputFillLight,
                        child: Icon(Icons.person, color: context.textHintColor),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job['clientName'] ?? '', style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.orange[400]),
                        const SizedBox(width: 4),
                        Text(job['location'] ?? '', style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoCard(context, 'cancel_cancellation_details'.tr, [
              _buildDetailRow(context, 'cancel_cancelled_by'.tr, job['cancelledBy'] ?? ''),
              const SizedBox(height: 8),
              Text('cancel_reason'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textHintColor)),
              const SizedBox(height: 4),
              Text(
                job['reason'] ?? '',
                style: AppStyles.bodyLarge.copyWith(color: AppColors.error, fontSize: 14),
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, 'cancel_job_info'.tr, [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: context.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(job['bookingDate']?.toString() ?? 'N/A', style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_filled, size: 16, color: context.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(job['preferredTime']?.toString() ?? 'N/A', style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: context.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text('${'cancel_service_fee'.tr}MAD ${job['budget'] ?? job['serviceFee'] ?? 0}', style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, 'cancel_service_description'.tr, [
              Text(
                job['description']?.toString() ?? 'No description provided.',
                style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5, color: context.textSecondaryColor),
              ),
            ]),
            const SizedBox(height: 24),
            CustomButton(
              text: 'cancel_contact_support'.tr,
              onPressed: () => Get.toNamed(Routes.customerService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
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
          Text(title, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppStyles.bodyMedium.copyWith(fontSize: 14, color: context.textSecondaryColor)),
        Text(value, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
