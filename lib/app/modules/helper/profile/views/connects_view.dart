import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectsView extends StatefulWidget {
  const ConnectsView({super.key});

  @override
  State<ConnectsView> createState() => _ConnectsViewState();
}

class _ConnectsViewState extends State<ConnectsView> {
  double balance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
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
          'connects_title'.tr,
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
                  Container(
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
                        Text(
                          'connects_balance'.tr,
                          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MAD ${balance.toStringAsFixed(2)}',
                          style: AppStyles.h1Of(context).copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Get.toNamed(Routes.connectsHistory),
                              child: Text(
                                'connects_view_details'.tr,
                                style: AppStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            GestureDetector(
                              onTap: () async {
                                await Get.toNamed(Routes.buyConnects);
                                if (mounted) _fetchBalance();
                              },
                              child: Text(
                                'connects_buy'.tr,
                                style: AppStyles.bodyLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 80, color: AppColors.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
    );
  }
}
