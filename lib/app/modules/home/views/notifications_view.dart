import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'notif_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'label_today'.tr),
            _buildNotificationCard(
              context,
              title: 'notifications_payment_done'.tr,
              subtitle: 'notifications_payment_success'.tr,
              iconColor: const Color(0xFF5AB9A7),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'label_yesterday'.tr),
            _buildNotificationCard(
              context,
              title: 'notifications_order_confirmed'.tr,
              subtitle: 'notifications_order_success'.tr,
              iconColor: const Color(0xFFFBBF24),
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              context,
              title: 'notifications_credit_connected'.tr,
              subtitle: 'notifications_credit_linked'.tr,
              iconColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, '28 Jan 2026'),
            _buildNotificationCard(
              context,
              title: 'notifications_account_setup'.tr,
              subtitle: 'notifications_order_success'.tr,
              iconColor: const Color(0xFFF97316),
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              context,
              title: 'notifications_payment_done'.tr,
              subtitle: 'notifications_payment_success'.tr,
              iconColor: const Color(0xFF5AB9A7),
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              context,
              title: 'notifications_order_confirmed'.tr,
              subtitle: 'notifications_order_success'.tr,
              iconColor: const Color(0xFFFBBF24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppStyles.bodyLargeOf(context).copyWith(
          fontSize: 16,
          color: context.textSecondaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
