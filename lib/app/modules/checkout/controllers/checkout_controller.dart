import 'dart:async';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckoutController extends GetxController {
  late final ApiClient _api;
  late final AuthService _authService;

  // Order Details from arguments
  final orderId = ''.obs;
  final orderType = 'job'.obs; // 'job' | 'offer' | 'wallet_topup'
  final amount = 0.0.obs;
  final currency = 'MAD'.obs;
  final title = 'Service Payment'.obs;
  final sessionId = ''.obs;
  final metadata = <String, dynamic>{}.obs;

  // State
  final selectedMethod = 'CashPlus'.obs;
  final isProcessing = false.obs;
  final isSuccess = false.obs;
  final errorMessage = ''.obs;

  final paymentMethods = [
    {
      'id': 'CashPlus',
      'name': 'CashPlus Morocco',
      'subtitle': 'Fast voucher & digital wallet payment',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFFE11D48),
    },
    {
      'id': 'ChariBaaS',
      'name': 'ChariBaaS Gateway',
      'subtitle': 'Instant Moroccan merchant checkout',
      'icon': Icons.payments_outlined,
      'color': Color(0xFF0D9488),
    },
    {
      'id': 'CMI',
      'name': 'Moroccan Bank Card (CMI)',
      'subtitle': 'Visa, Mastercard & Moroccan CMI cards',
      'icon': Icons.credit_card,
      'color': Color(0xFF2563EB),
    },
  ];

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiClient>();
    _authService = Get.find<AuthService>();

    _parseArguments();
  }

  void _parseArguments() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['orderId'] != null) orderId.value = args['orderId'].toString();
      if (args['orderType'] != null) orderType.value = args['orderType'].toString();
      if (args['amount'] != null) {
        amount.value = (args['amount'] as num).toDouble();
      }
      if (args['currency'] != null) currency.value = args['currency'].toString();
      if (args['title'] != null) title.value = args['title'].toString();
      if (args['sessionId'] != null) sessionId.value = args['sessionId'].toString();
      if (args['metadata'] is Map) {
        metadata.assignAll(Map<String, dynamic>.from(args['metadata']));
      }
    }

    final uid = _authService.currentUser.value?.id;
    if (uid != null && !metadata.containsKey('userId')) {
      metadata['userId'] = uid;
    }
  }

  void selectMethod(String methodId) {
    selectedMethod.value = methodId;
  }

  Future<void> confirmAndPay() async {
    if (isProcessing.value || isSuccess.value) return;
    isProcessing.value = true;
    errorMessage.value = '';

    final txnId = 'txn_sim_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';

    try {
      final response = await _api.post(
        '/payment/webhook',
        data: {
          'event': 'payment.success',
          'transactionId': txnId,
          'orderId': orderId.value,
          'orderType': orderType.value,
          'amount': amount.value,
          'currency': currency.value,
          'metadata': {
            ...metadata,
            'paymentMethod': selectedMethod.value,
            'userId': metadata['userId'] ?? _authService.currentUser.value?.id,
          },
        },
      );

      if (sessionId.value.isNotEmpty) {
        // Best-effort notify simulator container in the background without blocking the UI
        final simHost = ApiConstants.serverHost;
        final simUrl = 'http://$simHost:5099/simulator/v1/process-payment';
        unawaited(
          _api.client
              .post(
                simUrl,
                data: {
                  'sessionId': sessionId.value,
                  'action': 'success',
                },
              )
              .timeout(const Duration(seconds: 2))
              .catchError((_) => null as dynamic),
        );
      }

      if (response.success) {
        isSuccess.value = true;

        if (orderType.value == 'wallet_topup') {
          unawaited(() async {
            try {
              await Get.find<WalletService>().getWalletBalance();
            } catch (_) {}
          }());
        }

        // Short pause so user sees success — don't block on heavy refetch.
        await Future.delayed(const Duration(milliseconds: 700));
        Get.back(result: true);
      } else {
        errorMessage.value = response.message ?? 'Payment failed. Please try again.';
        AppFeedback.error(errorMessage.value, title: 'Payment failed');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      AppFeedback.error(errorMessage.value, title: 'Payment failed');
    } finally {
      isProcessing.value = false;
    }
  }

  /// User confirms cancel → mark payment failed, show feedback, leave checkout.
  /// Job stays pending_payment so they can pay later (new session).
  Future<void> cancelPayment() async {
    if (isProcessing.value) return;
    isProcessing.value = true;
    errorMessage.value = '';

    try {
      final txnId = 'txn_fail_${DateTime.now().millisecondsSinceEpoch}';
      final response = await _api.post(
        '/payment/webhook',
        data: {
          'event': 'payment.failed',
          'transactionId': txnId,
          'orderId': orderId.value,
          'orderType': orderType.value,
          'amount': amount.value,
          'currency': currency.value,
          'metadata': {
            ...metadata,
            'paymentMethod': selectedMethod.value,
            'userId': metadata['userId'] ?? _authService.currentUser.value?.id,
          },
        },
      );

      if (response.success) {
        AppFeedback.success(
          'You can try again later from Buy Connects or My Bookings.',
          title: 'Payment cancelled',
        );
      } else {
        // Still leave checkout — user asked to cancel
        AppFeedback.info(
          response.message ?? 'Checkout closed. Payment was not completed.',
          title: 'Payment cancelled',
        );
      }
    } catch (e) {
      AppFeedback.error(
        e.toString().replaceAll('Exception: ', ''),
        title: 'Could not update payment',
      );
    } finally {
      isProcessing.value = false;
      Get.back(result: false);
    }
  }

  void showCancelConfirm() {
    if (isProcessing.value || isSuccess.value) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel payment?'),
        content: Text(
          orderType.value == 'wallet_topup'
              ? 'Your wallet will not be charged. You can buy connects again later.'
              : 'You can complete this payment later from My Bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Keep paying'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Get.back(); // close dialog
              cancelPayment();
            },
            child: const Text('Cancel payment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
