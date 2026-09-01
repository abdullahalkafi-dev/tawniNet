import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectsHistoryView extends StatefulWidget {
  const ConnectsHistoryView({super.key});

  @override
  State<ConnectsHistoryView> createState() => _ConnectsHistoryViewState();
}

class _ConnectsHistoryViewState extends State<ConnectsHistoryView> {
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
          'connects_view_details'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('connects_view_details'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recharge Wallet Balance', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'MAD ${balance.toStringAsFixed(2)}',
                          style: AppStyles.h1Of(context).copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Get.toNamed(Routes.buyConnects),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          child: Text('connects_buy'.tr, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
