import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyConnectsView extends StatefulWidget {
  const BuyConnectsView({super.key});

  @override
  State<BuyConnectsView> createState() => _BuyConnectsViewState();
}

class _BuyConnectsViewState extends State<BuyConnectsView> {
  String selectedPackage = '10 for MAD 1.50';
  double currentBalance = 0.0;
  bool isLoading = true;

  final Map<String, int> packageAmounts = {
    '10 for MAD 1.50': 10,
    '20 for MAD 3.00': 20,
    '40 for MAD 6.00': 40,
    '60 for MAD 9.00': 60,
    '80 for MAD 12.00': 80,
    '100 for MAD 15.00': 100,
    '150 for MAD 22.50': 150,
    '200 for MAD 30.00': 200,
    '250 for MAD 37.50': 250,
    '300 for MAD 45.00': 300,
  };

  final Map<String, double> packagePrices = {
    '10 for MAD 1.50': 1.50,
    '20 for MAD 3.00': 3.00,
    '40 for MAD 6.00': 6.00,
    '60 for MAD 9.00': 9.00,
    '80 for MAD 12.00': 12.00,
    '100 for MAD 15.00': 15.00,
    '150 for MAD 22.50': 22.50,
    '200 for MAD 30.00': 30.00,
    '250 for MAD 37.50': 37.50,
    '300 for MAD 45.00': 45.00,
  };

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
          currentBalance = (res['balance'] as num?)?.toDouble() ?? 0.0;
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
                      child: DropdownButton<String>(
                        value: selectedPackage,
                        dropdownColor: context.cardColor,
                        isExpanded: true,
                        items: packageAmounts.keys.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item, style: AppStyles.bodyMedium.copyWith(color: context.textPrimaryColor)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) setState(() => selectedPackage = newValue);
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
                    'MAD ${(currentBalance + (packagePrices[selectedPackage] ?? 0.0)).toStringAsFixed(2)}',
                    style: AppStyles.h1Of(context).copyWith(fontSize: 28),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
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
                          onPressed: () async {
                            try {
                              final walletService = Get.find<WalletService>();
                              final amount = packagePrices[selectedPackage] ?? 10.0;
                              final res = await walletService.topupWallet(amount);
                              final checkoutUrl = res['checkoutUrl'] ?? res['paymentUrl'];
                              if (checkoutUrl != null) {
                                final uri = Uri.parse(checkoutUrl.toString());
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  Get.snackbar('Top-Up Link', checkoutUrl.toString(), snackPosition: SnackPosition.BOTTOM);
                                }
                              }
                            } catch (e) {
                              Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''), snackPosition: SnackPosition.BOTTOM);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('connects_buy'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
