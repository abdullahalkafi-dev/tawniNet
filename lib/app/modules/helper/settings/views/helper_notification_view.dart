import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperNotificationView extends StatelessWidget {
  const HelperNotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings_notification'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, 'label_today'.tr, [
              _buildNotificationItem(context, 'notifications_payment_done'.tr, 'notifications_payment_success'.tr, AppColors.primary, Icons.notifications),
            ]),
            const SizedBox(height: 20),
            _buildSection(context, 'label_yesterday'.tr, [
              _buildNotificationItem(context, 'notifications_order_confirmed'.tr, 'notifications_order_success'.tr, Colors.orange, Icons.notifications),
              _buildNotificationItem(context, 'notifications_credit_connected'.tr, 'notifications_credit_linked'.tr, AppColors.primary, Icons.notifications),
            ]),
            const SizedBox(height: 20),
            _buildSection(context, '28 Jan 2026', [
              _buildNotificationItem(context, 'notifications_account_setup'.tr, 'notifications_order_success'.tr, Colors.orange, Icons.notifications),
              _buildNotificationItem(context, 'notifications_payment_done'.tr, 'notifications_payment_success'.tr, AppColors.primary, Icons.notifications),
              _buildNotificationItem(context, 'notifications_order_confirmed'.tr, 'notifications_order_success'.tr, Colors.orange, Icons.notifications),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor, fontSize: 14)),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildNotificationItem(BuildContext context, String title, String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message, style: AppStyles.bodyMedium.copyWith(fontSize: 13, color: context.textSecondaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
