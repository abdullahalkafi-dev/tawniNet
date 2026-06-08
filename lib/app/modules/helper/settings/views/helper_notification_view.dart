import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperNotificationView extends StatelessWidget {
  const HelperNotificationView({super.key});

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
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Today', [
              _buildNotificationItem('Payment Done', 'Your payment has been done successfully', AppColors.primary, Icons.notifications),
            ]),
            const SizedBox(height: 20),
            _buildSection('Yesterday', [
              _buildNotificationItem('Order Confirmed', 'Your order has been confirmed', Colors.orange, Icons.notifications),
              _buildNotificationItem('Credit Card Connected', 'Credit Card has been Linked', AppColors.primary, Icons.notifications),
            ]),
            const SizedBox(height: 20),
            _buildSection('28 Jan 2026', [
              _buildNotificationItem('Account Setup Successful', 'Your order has been confirmed', Colors.orange, Icons.notifications),
              _buildNotificationItem('Payment Done', 'Your payment has been done successfully', AppColors.primary, Icons.notifications),
              _buildNotificationItem('Order Confirmed', 'Your order has been confirmed', Colors.orange, Icons.notifications),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildNotificationItem(String title, String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
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
                Text(title, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message, style: AppStyles.bodyMedium.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
