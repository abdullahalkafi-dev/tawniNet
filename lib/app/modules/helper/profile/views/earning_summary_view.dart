import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarningSummaryView extends StatefulWidget {
  const EarningSummaryView({super.key});

  @override
  State<EarningSummaryView> createState() => _EarningSummaryViewState();
}

class _EarningSummaryViewState extends State<EarningSummaryView> {
  double balance = 0.0;
  double jobEarnings = 0.0;
  double platformFees = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final walletService = Get.find<WalletService>();
      final res = await walletService.getWalletBalance();
      if (mounted) {
        final transactions = (res['transactions'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        double earnings = 0.0;
        double fees = 0.0;
        for (final t in transactions) {
          final type = (t['type'] ?? '').toString();
          final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
          if (type == 'earning_payout' || type == 'commission_refund') {
            earnings += amount;
          } else if (type == 'commission_deduction') {
            fees += amount.abs();
          }
        }

        setState(() {
          balance = (res['balance'] as num?)?.toDouble() ?? 0.0;
          jobEarnings = earnings;
          platformFees = fees;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = 'MAD ${balance.toStringAsFixed(2)}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'earning_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalEarningsCard(formattedBalance),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEarningTypeCard(
                          context,
                          'earning_job_earnings'.tr,
                          'MAD ${jobEarnings.toStringAsFixed(2)}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEarningTypeCard(
                          context,
                          'earning_platform_fees'.tr,
                          'MAD ${platformFees.toStringAsFixed(2)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(context, 'earning_jobs_completed'.tr, 'Active'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(context, 'earning_fees'.tr, 'MAD ${platformFees.toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('earning_next'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
                  Divider(height: 30, color: context.borderSubtle),
                  Text('earning_mature_amount'.tr, style: AppStyles.bodyLargeOf(context).copyWith(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('earning_estimate'.tr, style: AppStyles.bodyLargeOf(context).copyWith(fontSize: 14)),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalEarningsCard(String formattedBalance) {
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
            'earning_total'.tr,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            formattedBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTypeCard(BuildContext context, String title, String amount) {
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
          Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            amount,
            style: AppStyles.h2Of(context).copyWith(fontSize: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: context.textHintColor, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
