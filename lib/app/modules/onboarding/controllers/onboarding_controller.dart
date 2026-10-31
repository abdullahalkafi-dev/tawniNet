import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/localization/locale_service.dart';
import '../../../services/storage_service.dart';
import '../../splash/controllers/splash_controller.dart' show kOnboardingDoneKey;

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void next() {
    if (currentPage.value < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _finish();
    }
  }

  void skip() => _finish();

  /// The slides are shown once: remember it, then go to the role choice.
  void _finish() {
    Get.find<StorageService>().write(kOnboardingDoneKey, '1');
    Get.offAllNamed(Routes.roleSelection);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void toggleLanguage() {
    Get.find<LocaleService>().toggleLocale();
  }
}
