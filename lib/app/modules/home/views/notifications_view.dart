import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Notification',
          style: AppStyles.h2.copyWith(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Today'),
            _buildNotificationCard(
              title: 'Payment Done',
              subtitle: 'Your payment has been done successfully',
              iconColor: const Color(0xFF5AB9A7),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Yesterday'),
            _buildNotificationCard(
              title: 'Order Confirmed',
              subtitle: 'Your order has been confirmed',
              iconColor: const Color(0xFFFBBF24),
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              title: 'Credit Card Connected',
              subtitle: 'Credit Card has been Linked',
              iconColor: const Color(0xFF10B981),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('28 Jan 2026'),
            _buildNotificationCard(
              title: 'Account Setup Successful',
              subtitle: 'Your order has been confirmed',
              iconColor: const Color(0xFFF97316),
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              title: 'Payment Done',
              subtitle: 'Your payment has been done successfully',
              iconColor: const Color(0xFF5AB9A7),
            ),
            const SizedBox(height: 12),
            _buildNotificationCard(
              title: 'Order Confirmed',
              subtitle: 'Your order has been confirmed',
              iconColor: const Color(0xFFFBBF24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppStyles.bodyLarge.copyWith(
          fontSize: 16,
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppStyles.bodyMedium.copyWith(
                    color: const Color(0xFF6B7280),
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
