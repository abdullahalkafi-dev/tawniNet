import 'package:flutter/foundation.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/app_config_service.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/notification_service.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:get/get.dart';

/// Storage key: the introduction slides were seen (shown once, not at every launch).
const kOnboardingDoneKey = 'onboarding_done';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateToNext();
  }

  void _navigateToNext() async {
    final authService = Get.find<AuthService>();
    final started = DateTime.now();

    // The saved session and the server settings load while the logo shows.
    try {
      await authService.ready.future.timeout(const Duration(seconds: 5));
    } catch (_) {}
    var config = Get.isRegistered<AppConfigService>() ? Get.find<AppConfigService>() : null;
    if (config != null && !config.isLoaded) {
      try {
        await config.refresh().timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    // Logged-in users: take the freshest profile BEFORE choosing a screen, so
    // a user who was blocked / approved / rejected meanwhile lands in the right place.
    if (authService.isLoggedIn.value) {
      await authService.refreshSession();
    }

    // A short brand beat only (never a fixed multi-second wait).
    final elapsed = DateTime.now().difference(started);
    const minimum = Duration(milliseconds: 700);
    if (elapsed < minimum) await Future.delayed(minimum - elapsed);
    if (isClosed) return;

    if (Get.currentRoute != Routes.splash) {
      debugPrint('[Splash] Route is ${Get.currentRoute} — yielding navigation');
      return;
    }

    if (Get.isRegistered<NotificationService>() &&
        Get.find<NotificationService>().isColdStartHandling) {
      return;
    }

    config = Get.isRegistered<AppConfigService>() ? Get.find<AppConfigService>() : null;
    if (config != null && config.updateRequired) {
      Get.offAllNamed(Routes.updateRequired);
      return;
    }

    if (authService.isLoggedIn.value) {
      final user = authService.currentUser.value;
      if (user == null) {
        Get.offAllNamed(Routes.roleSelection);
        return;
      }
      authService.goToDestination();
    } else {
      // The introduction is shown once; afterwards straight to the role choice.
      final seen = await Get.find<StorageService>().read(kOnboardingDoneKey);
      if (isClosed || Get.currentRoute != Routes.splash) return;
      Get.offAllNamed(seen == '1' ? Routes.roleSelection : Routes.onboarding);
    }
  }
}
