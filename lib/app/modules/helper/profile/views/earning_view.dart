import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EarningView extends StatelessWidget {
  const EarningView({super.key});

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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Revenue'),
                Tab(text: 'Withdrawals'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRevenueTable(),
                  _buildWithdrawalsTable(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTable() {
    final records = [
      {'date': '02/04/26', 'activity': 'Clearing', 'method': 'Online', 'from': 'T-trades', 'amount': '+\$25.00'},
      {'date': '25/01/26', 'activity': 'Clearing', 'method': 'Offline', 'from': 'Kafi', 'amount': '+\$37.00'},
      {'date': '15/04/26', 'activity': 'Clearing', 'method': 'Offline', 'from': 'Rosul', 'amount': '+\$09.00'},
      {'date': '19/02/26', 'activity': 'Withdrawal', 'method': 'Transferred successfully', 'from': 'Payoneer', 'amount': '+\$25.00', 'isWithdrawal': true},
      {'date': '05/03/26', 'activity': 'Earning', 'method': 'Online', 'from': 'T-trades', 'amount': '+\$10.00'},
      {'date': '19/02/26', 'activity': 'Earning', 'method': 'Offline', 'from': 'Dusher', 'amount': '+\$20.00'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTableHeader(),
          ...records.map((r) => _buildTableRow(r)),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsTable() {
    final records = [
      {'date': '19/02/26', 'activity': 'Withdrawal', 'method': 'Transferred successfully', 'from': 'Payoneer', 'amount': '+\$25.00', 'isWithdrawal': true},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTableHeader(),
          ...records.map((r) => _buildTableRow(r)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text('Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 3, child: Text('Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text('From', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map record) {
    final isWithdrawal = record['isWithdrawal'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(record['date'], style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text(record['activity'], style: const TextStyle(fontSize: 12))),
          Expanded(flex: 3, child: Text(record['method'], style: const TextStyle(fontSize: 12))),
          Expanded(flex: 2, child: Text(record['from'], style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: Text(
              record['amount'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isWithdrawal ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
