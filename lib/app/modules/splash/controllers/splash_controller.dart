import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('SplashController: onInit');
  }

  @override
  void onReady() {
    super.onReady();
    print('SplashController: onReady');
    _navigateToNext();
  }

  void _navigateToNext() async {
    print('SplashController: Starting timer...');
    await Future.delayed(const Duration(seconds: 3));
    print('SplashController: Navigating to Onboarding...');
    Get.offAllNamed(Routes.onboarding);
  }
}
