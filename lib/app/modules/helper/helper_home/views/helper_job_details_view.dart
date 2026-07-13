import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperJobDetailsView extends StatelessWidget {
  const HelperJobDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final HelperJob job = Get.arguments;

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
          'job_details_title'.tr,
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobInfoCard(job),
            const SizedBox(height: 16),
            _buildCustomerInfo(),
            const SizedBox(height: 16),
            _buildJobDescriptionWithPhotos(),
            const SizedBox(height: 16),
            _buildPaymentBreakdown(),
            const SizedBox(height: 16),
            CustomButton(
              text: 'job_accept'.tr,
              onPressed: () {
                Get.back();
                Get.snackbar('job_accepted'.tr, 'job_accepted_success'.tr,
                    snackPosition: SnackPosition.BOTTOM);
              },
            ),
            const SizedBox(height: 16),
            _buildJobStatusTimeline(),
          ],
        ),
      ),
      bottomNavigationBar: _buildInputBar(),
    );
  }

  Widget _buildJobInfoCard(HelperJob job) {
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
          Text(job.title, style: AppStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Flexible(child: Text('job_sunday'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 16),
              Icon(Icons.access_time_filled, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Flexible(child: Text('job_time_range'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Flexible(child: Text('job_address'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text('job_distance'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo() {
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
          Text('job_customer_info'.tr, style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  'https://i.pravatar.cc/150?u=customer1',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 44,
                      height: 44,
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
                  Text('T-trades', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  Text('Homeowner', style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: AppColors.textHint),
              const SizedBox(width: 4),
              Flexible(child: Text('job_address'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescriptionWithPhotos() {
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
          Text('label_job_description'.tr, style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Text('label_tasks_required'.tr, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum. Lorem quam vitae mus metus tortor turpis at. Cras accumsan pharetra odio euismod metus leo neque dui. More',
            style: AppStyles.bodyMedium.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Text('label_photos'.tr, style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://i.pravatar.cc/150?u=photo$index',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
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
          Text('job_payment_breakdown'.tr, style: AppStyles.h2.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          _buildPaymentRow('job_payment'.tr, 'MAD 100.00'),
          const SizedBox(height: 8),
          _buildPaymentRow('job_platform_fee'.tr, '-MAD 12.00', isNegative: true),
          const Divider(height: 30),
          _buildPaymentRow('job_your_earnings'.tr, 'MAD 88.00', isBold: true),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.black),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'job_payment_note'.tr,
                    style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isNegative = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.bodyLarge.copyWith(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppStyles.bodyLarge.copyWith(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isNegative ? AppColors.error : (isBold ? Colors.black : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildJobStatusTimeline() {
    final steps = [
      {'label': 'job_status_submitted'.tr, 'date': 'Jan 8, 2025 at 2:30 PM', 'completed': true},
      {'label': 'job_status_accepted'.tr, 'date': 'Jan 9, 2025 at 8:15 AM', 'completed': true},
      {'label': 'status_in_progress'.tr, 'date': 'Pending', 'completed': false},
      {'label': 'status_completed'.tr, 'date': 'Pending', 'completed': false},
      {'label': 'status_payment_processed'.tr, 'date': 'Pending', 'completed': false},
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
          Text('label_job_status'.tr, style: AppStyles.h2.copyWith(fontSize: 16)),
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
                        color: step['completed'] as bool ? AppColors.primary : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: (step['completed'] as bool)
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 30,
                        color: const Color(0xFFE5E7EB),
                      ),
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
                      Text(
                        step['date'] as String,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.image_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'label_type_message'.tr,
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
