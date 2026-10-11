import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/checkout_controller.dart';

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Allow system pop only when not processing and not showing success
      // (success uses handleBack → Navigator.pop with result true).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.handleBack,
          ),
          title: Text(
            'checkout_title'.tr,
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Obx(() {
          if (controller.isSuccess.value) {
            return _buildSuccessView(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummaryCard(context),
                const SizedBox(height: 24),
                Text(
                  'checkout_select_channel'.tr,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.paymentMethods.map(
                  (method) => _buildPaymentMethodCard(context, method),
                ),
                const SizedBox(height: 24),
                _buildSecurityNotice(context),
                if (controller.errorMessage.value.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.isDarkMode
                            ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                            : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(
                        color: context.isDarkMode
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFF991B1B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildActionButtons(context),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Expanded(
                child: Text(
                  controller.title.value.isNotEmpty
                      ? controller.title.value
                      : 'checkout_service_checkout'.tr,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.orderType.value.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          if (controller.orderId.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${'checkout_order_id'.tr}: ${controller.orderId.value}',
              style: AppStyles.bodyMediumOf(context).copyWith(
                fontSize: 12,
                color: context.textHintColor,
                fontFamily: 'monospace',
              ),
            ),
          ],
          Divider(height: 28, color: context.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout_total_to_pay'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                'MAD ${controller.amount.value.toStringAsFixed(2)}',
                style: AppStyles.h1Of(context).copyWith(
                  fontSize: 22,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    Map<String, dynamic> method,
  ) {
    return Obx(() {
      final isSelected = controller.selectedMethod.value == method['id'];
      final color = method['color'] as Color;

      return GestureDetector(
        onTap: () => controller.selectMethod(method['id'] as String),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.04) : context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : context.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(method['icon'] as IconData, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'] as String,
                      style: AppStyles.bodyLargeOf(context).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method['subtitle'] as String,
                      style: AppStyles.bodyMediumOf(context).copyWith(
                        fontSize: 12,
                        color: context.textHintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? color : context.textHintColor,
                size: 22,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSecurityNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.green.withOpacity(0.12)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.green.withOpacity(0.3)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'checkout_security_guarantee'.tr,
              style: TextStyle(
                color: context.isDarkMode ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isProcessing.value
                ? null
                : controller.confirmAndPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: controller.isProcessing.value
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '${'checkout_confirm_pay'.tr} MAD ${controller.amount.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: controller.isProcessing.value
                ? null
                : controller.showCancelConfirm,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: context.isDarkMode
                    ? const Color(0xFFEF4444).withOpacity(0.6)
                    : Colors.red.shade300,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'checkout_cancel_payment'.tr,
              style: TextStyle(
                color: context.isDarkMode
                    ? const Color(0xFFF87171)
                    : Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'checkout_payment_successful'.tr,
              style: AppStyles.h1Of(context).copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'MAD ${controller.amount.value.toStringAsFixed(2)} ${'checkout_payment_verified'.tr}',
              textAlign: TextAlign.center,
              style: AppStyles.bodyMediumOf(context).copyWith(
                color: context.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(strokeWidth: 2),
            const SizedBox(height: 12),
            Text(
              'checkout_returning_app'.tr,
              style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.completeSuccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'btn_done'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
