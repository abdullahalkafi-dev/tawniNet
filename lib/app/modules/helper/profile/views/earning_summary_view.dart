import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarningSummaryView extends StatelessWidget {
  const EarningSummaryView({super.key});

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
          'Earning',
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalEarningsCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildEarningTypeCard('Online Earnings', '\$3,250.00')),
                const SizedBox(width: 12),
                Expanded(child: _buildEarningTypeCard('Offline Earnings', '\$1,000.00')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Jobs Completed', '25')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Withdrawals', '2')),
              ],
            ),
            const SizedBox(height: 24),
            Text('Next earning', style: AppStyles.h2.copyWith(fontSize: 18)),
            const Divider(height: 30),
            Text('Current mature amount MAD 300', style: AppStyles.bodyLarge.copyWith(fontSize: 14)),
            const SizedBox(height: 8),
            Text('Estimate Payment MAD 300', style: AppStyles.bodyLarge.copyWith(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$1,250.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTypeCard(String title, String amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.primary, fontSize: 12)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: AppStyles.h1.copyWith(fontSize: 24)),
        ],
      ),
    );
  }
}
