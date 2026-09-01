import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/localization/locale_service.dart';

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
      Get.offAllNamed(Routes.roleSelection);
    }
  }

  void skip() {
    Get.offAllNamed(Routes.roleSelection);
  }

  void toggleLanguage() {
    Get.find<LocaleService>().toggleLocale();
  }
}
