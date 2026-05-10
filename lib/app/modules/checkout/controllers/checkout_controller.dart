import 'package:get/get.dart';

class CheckoutController extends GetxController {
  final selectedMethod = 'PayPal'.obs;

  void confirmAndPay() {
    print('Payment Confirmed');
    Get.back(); // Back to home or success screen
  }
}
