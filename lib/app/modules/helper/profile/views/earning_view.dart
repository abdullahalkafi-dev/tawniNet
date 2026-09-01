import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarningView extends StatefulWidget {
  const EarningView({super.key});

  @override
  State<EarningView> createState() => _EarningViewState();
}

class _EarningViewState extends State<EarningView> {
  double balance = 0.0;
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
        setState(() {
          balance = (res['balance'] as num?)?.toDouble() ?? 0.0;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: context.textHintColor,
                    labelStyle:
                        AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'earning_revenue'.tr),
                      Tab(text: 'earning_withdrawals'.tr),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRevenueTable(context),
                        _buildWithdrawalsTable(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueTable(BuildContext context) {
    final records = [
      {
        'date': 'Today',
        'activity': 'Earning',
        'method': 'Online',
        'from': 'Commission',
        'amount': '+MAD ${balance.toStringAsFixed(2)}',
        'isWithdrawal': false,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTableHeader(context),
          ...records.map((r) => _buildTableRow(context, r)),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsTable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No withdrawal records found.',
          style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('earning_date'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text('earning_activity'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 3,
            child: Text('earning_method'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text('earning_from'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text('earning_amount'.tr,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: context.textPrimaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Map record) {
    final isWithdrawal = record['isWithdrawal'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(record['date'], style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(record['activity'], style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(record['method'], style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(record['from'], style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              record['amount'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isWithdrawal ? Colors.red : Colors.green[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
