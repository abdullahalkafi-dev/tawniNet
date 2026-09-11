import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
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
    final job = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    final cancelledDate = job['cancelledAt'] != null
        ? AppDateTime.formatDateDisplay(job['cancelledAt'].toString())
        : JobDisplay.safeText(job['cancelledDate'], fallback: 'Recently');
    final clientName = JobDisplay.personName(job['postedBy'],
        fallback: JobDisplay.safeText(job['clientName']));
    final clientAvatar = JobDisplay.personAvatar(job['postedBy'],
        fallback: JobDisplay.safeText(job['clientImage'],
            fallback: 'https://i.pravatar.cc/150?u=default'));
    final location = JobDisplay.publicAddress(job);
    final reason = JobDisplay.safeText(job['cancellationReason'],
        fallback: JobDisplay.safeText(job['reason'], fallback: 'No reason provided'));
    final cancelledByRaw = job['cancelledBy'];
    String cancelledBy = '—';
    if (cancelledByRaw is Map) {
      cancelledBy = JobDisplay.safeText(cancelledByRaw['name'], fallback: 'User');
    } else if (cancelledByRaw != null) {
      final id = cancelledByRaw.toString();
      final helperId = JobDisplay.safeText(
        job['assignedTo'] is Map ? job['assignedTo']['_id'] : null,
      );
      final clientId = JobDisplay.safeText(
        job['postedBy'] is Map ? job['postedBy']['_id'] : null,
      );
      if (helperId.isNotEmpty && id == helperId) {
        cancelledBy = 'Helper';
      } else if (clientId.isNotEmpty && id == clientId) {
        cancelledBy = 'Client';
      } else {
        cancelledBy = 'User';
      }
    }
    final bookingDateRaw = job['date'] ?? job['createdAt'];
    final bookingDate = bookingDateRaw != null
        ? AppDateTime.formatDateDisplay(bookingDateRaw.toString())
        : 'N/A';
    final preferredTime = job['startTime'] != null
        ? [
            AppDateTime.formatTime12h(job['startTime']?.toString()),
            if (job['endTime'] != null)
              AppDateTime.formatTime12h(job['endTime']?.toString()),
          ].where((t) => t.isNotEmpty).join(' - ')
        : JobDisplay.safeText(job['preferredTime'], fallback: 'N/A');
    final budgetRaw = job['budget'] ?? job['serviceFee'] ?? 0;
    final budget = budgetRaw is num
        ? budgetRaw
        : (num.tryParse(budgetRaw.toString()) ?? 0);

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
                    '${'cancel_job_cancelled_on'.tr} $cancelledDate',
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
                    clientAvatar.isNotEmpty ? clientAvatar : 'https://i.pravatar.cc/150?u=default',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.orange[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor),
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
            const SizedBox(height: 20),
            _buildInfoCard(context, 'cancel_cancellation_details'.tr, [
              _buildDetailRow(context, 'cancel_cancelled_by'.tr, cancelledBy),
              const SizedBox(height: 8),
              Text('cancel_reason'.tr, style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textHintColor)),
              const SizedBox(height: 4),
              Text(
                reason,
                style: AppStyles.bodyLarge.copyWith(color: AppColors.error, fontSize: 14),
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard(context, 'cancel_job_info'.tr, [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: context.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(bookingDate, style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time_filled, size: 16, color: context.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(preferredTime, style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: context.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text('MAD ${budget.toStringAsFixed(0)}', style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13)),
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
              onPressed: () => Get.toNamed(Routes.supportTicketList),
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
