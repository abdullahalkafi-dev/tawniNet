import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'checkout_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSummaryCard(context),
            const SizedBox(height: 24),
            _buildPaymentMethodTile(context, 'checkout_paypal'.tr, 'checkout_connected'.tr, true),
            const SizedBox(height: 16),
            _buildPaymentMethodTile(context, 'checkout_paypal'.tr, 'checkout_connected'.tr, false),
            const SizedBox(height: 16),
            _buildAddMethodTile(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout_service_name'.tr,
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '35 MAD',
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'checkout_include_service'.tr,
            style: AppStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Lorem ipsum dolor sit amet consectetur. Elit ac gravida augue suspendisse in scelerisque pellentesque diam elementum. Lorem quam vitae mus metus tortor turpis at. Cras accumsan pharetra odio euismod metus leo neque duis. More',
            style: AppStyles.bodyMediumOf(context).copyWith(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
          ),
          Divider(height: 32, color: context.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout_total'.tr,
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '36.10 MAD',
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout_delivery_time'.tr,
                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              ),
              Text(
                'checkout_hour'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: controller.confirmAndPay,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'checkout_confirm_pay'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'checkout_secure'.tr,
              style: TextStyle(color: context.textHintColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(BuildContext context, String name, String status, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: Colors.blue, size: 30),
          const SizedBox(width: 12),
          Text(
            name,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            status,
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMethodTile(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle, style: BorderStyle.solid),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: context.textPrimaryColor),
          const SizedBox(width: 8),
          Text(
            'checkout_add_method'.tr,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
