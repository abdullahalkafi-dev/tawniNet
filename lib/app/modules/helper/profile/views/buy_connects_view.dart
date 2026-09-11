import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class _ConnectPackage {
  final int connects;
  final double price;

  const _ConnectPackage({required this.connects, required this.price});
}

class BuyConnectsView extends StatefulWidget {
  const BuyConnectsView({super.key});

  @override
  State<BuyConnectsView> createState() => _BuyConnectsViewState();
}

class _BuyConnectsViewState extends State<BuyConnectsView> {
  double currentBalance = 0.0;
  bool isLoading = true;
  bool isPurchasing = false;

  static const List<_ConnectPackage> _packages = [
    _ConnectPackage(connects: 10, price: 1.50),
    _ConnectPackage(connects: 20, price: 3.00),
    _ConnectPackage(connects: 40, price: 6.00),
    _ConnectPackage(connects: 60, price: 9.00),
    _ConnectPackage(connects: 80, price: 12.00),
    _ConnectPackage(connects: 100, price: 15.00),
    _ConnectPackage(connects: 150, price: 22.50),
    _ConnectPackage(connects: 200, price: 30.00),
    _ConnectPackage(connects: 250, price: 37.50),
    _ConnectPackage(connects: 300, price: 45.00),
  ];

  _ConnectPackage _selectedPackage = _packages.first;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance({bool silent = false}) async {
    if (!silent && mounted) setState(() => isLoading = true);
    try {
      final walletService = Get.find<WalletService>();
      final res = await walletService.getWalletBalance();
      if (mounted) {
        setState(() {
          currentBalance = (res['balance'] as num?)?.toDouble() ?? 0.0;
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _startPurchase() async {
    if (isPurchasing || isLoading) return;
    setState(() => isPurchasing = true);
    try {
      final walletService = Get.find<WalletService>();
      final amount = _selectedPackage.price;
      final res = await walletService.topupWallet(amount);
      final sessId = res['sessionId']?.toString() ?? '';
      // Prefer real orderId (topup_*). Older backends only return
      // transactionId (init_*) — webhook still resolves that via legacy lookup.
      var orderId = res['orderId']?.toString() ?? '';
      if (orderId.isEmpty) {
        orderId = res['transactionId']?.toString() ?? '';
      }
      if (orderId.isEmpty) {
        throw Exception('Payment session missing orderId');
      }

      if (!mounted) return;
      final paid = await Get.toNamed(
        Routes.checkout,
        arguments: {
          'orderId': orderId,
          'orderType': 'wallet_topup',
          'amount': amount,
          'currency': 'MAD',
          'title': 'Recharge Wallet Top-Up',
          'sessionId': sessId,
        },
      );

      if (paid == true && mounted) {
        await _fetchBalance(silent: true);
      }
    } catch (e) {
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isPurchasing,
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isPurchasing ? null : () => Get.back(),
        ),
        title: Text(
          'connects_buy'.tr,
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
                  Text(
                    'Recharge Wallet Balance',
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MAD ${currentBalance.toStringAsFixed(2)}',
                    style: AppStyles.h1Of(context).copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'connects_select_amount'.tr,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      border: Border.all(color: context.borderSubtle),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_ConnectPackage>(
                        value: _selectedPackage,
                        dropdownColor: context.cardColor,
                        isExpanded: true,
                        items: _packages.map((pkg) {
                          return DropdownMenuItem<_ConnectPackage>(
                            value: pkg,
                            child: Text(
                              'MAD ${pkg.price.toStringAsFixed(2)}',
                              style: AppStyles.bodyMedium.copyWith(
                                color: context.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: isPurchasing
                            ? null
                            : (pkg) {
                                if (pkg != null) setState(() => _selectedPackage = pkg);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'New Balance after Top-Up',
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MAD ${(currentBalance + _selectedPackage.price).toStringAsFixed(2)}',
                    style: AppStyles.h1Of(context).copyWith(fontSize: 28),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isPurchasing ? null : () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('btn_cancel'.tr, style: AppStyles.buttonText.copyWith(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isPurchasing ? null : _startPurchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isPurchasing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text('connects_buy'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
