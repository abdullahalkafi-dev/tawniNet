import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EarningView extends StatefulWidget {
  const EarningView({super.key});

  @override
  State<EarningView> createState() => _EarningViewState();
}

class _EarningViewState extends State<EarningView> {
  double balance = 0.0;
  List<Map<String, dynamic>> transactions = [];
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
          transactions = (res['transactions'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt.toString());
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      if (dateOnly == today) return 'Today';
      if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }

  String _getActivityLabel(String type) {
    switch (type) {
      case 'commission_deduction':
        return 'Platform Fee';
      case 'commission_refund':
        return 'Fee Refund';
      case 'earning_payout':
        return 'Job Earning';
      default:
        return 'Transaction';
    }
  }

  String _getMethodLabel(String type) {
    switch (type) {
      case 'commission_deduction':
        return 'Platform Fee';
      case 'commission_refund':
        return 'Refund';
      case 'earning_payout':
        return 'Job Payout';
      default:
        return 'Other';
    }
  }

  bool _isRevenue(String type) {
    return type == 'commission_refund' || type == 'earning_payout';
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
                      Tab(text: 'earning_fees'.tr),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRevenueTable(context),
                        _buildFeesTable(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRevenueTable(BuildContext context) {
    final revenueTransactions = transactions.where((t) {
      final type = (t['type'] ?? '').toString();
      return _isRevenue(type);
    }).toList();

    if (revenueTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'earning_no_revenue'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTableHeader(context),
          ...revenueTransactions.map((t) => _buildTableRow(context, t)),
        ],
      ),
    );
  }

  Widget _buildFeesTable(BuildContext context) {
    final feeTransactions = transactions.where((t) {
      final type = (t['type'] ?? '').toString();
      return type == 'commission_deduction';
    }).toList();

    if (feeTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'earning_no_fees'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTableHeader(context),
          ...feeTransactions.map((t) => _buildTableRow(context, t)),
        ],
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

  Widget _buildTableRow(BuildContext context, Map<String, dynamic> record) {
    final type = (record['type'] ?? '').toString();
    final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;
    final description = (record['description'] ?? '').toString();
    final isCredit = _isRevenue(type);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(_formatDate(record['createdAt']),
                style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(_getActivityLabel(type),
                style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 3,
            child: Text(_getMethodLabel(type),
                style: TextStyle(fontSize: 12, color: context.textPrimaryColor)),
          ),
          Expanded(
            flex: 2,
            child: Text(description.isNotEmpty ? description : '—',
                style: TextStyle(fontSize: 12, color: context.textHintColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isCredit ? '+' : '-'}MAD ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.green[600] : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
