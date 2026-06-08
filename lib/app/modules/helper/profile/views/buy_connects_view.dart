import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BuyConnectsView extends StatefulWidget {
  const BuyConnectsView({super.key});

  @override
  State<BuyConnectsView> createState() => _BuyConnectsViewState();
}

class _BuyConnectsViewState extends State<BuyConnectsView> {
  String selectedPackage = '10 for MAD 1.50';
  final int currentBalance = 30;
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

  @override
  Widget build(BuildContext context) {
    final addedConnects = packageAmounts[selectedPackage] ?? 10;

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
          'Buy Connects',
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your available Connects',
              style: AppStyles.bodyMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '$currentBalance',
              style: AppStyles.h1.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 24),
            Text(
              'Select the amount to buy',
              style: AppStyles.bodyMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPackage,
                  isExpanded: true,
                  items: packageAmounts.keys.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item, style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
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
              'Your new Connects balance will be',
              style: AppStyles.bodyMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${currentBalance + addedConnects}',
              style: AppStyles.h1.copyWith(fontSize: 28),
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
                    child: Text('Cancel', style: AppStyles.buttonText.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.snackbar('Success', 'Connects purchased successfully',
                          snackPosition: SnackPosition.BOTTOM);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Buy Connects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
