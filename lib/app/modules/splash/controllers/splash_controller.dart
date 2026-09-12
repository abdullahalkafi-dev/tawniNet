import 'package:flutter/foundation.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/notification_service.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateToNext();
  }

  void _navigateToNext() async {
    final authService = Get.find<AuthService>();
    // Returning users: short branding beat so resume feels instant.
    // Cold first-open: keep a longer splash.
    final delay = authService.isLoggedIn.value
        ? const Duration(milliseconds: 400)
        : const Duration(seconds: 3);
    await Future.delayed(delay);
    if (isClosed) return;

    if (Get.currentRoute != Routes.splash) {
      debugPrint('[Splash] Route is ${Get.currentRoute} — yielding navigation');
      return;
    }

    if (Get.isRegistered<NotificationService>() &&
        Get.find<NotificationService>().isColdStartHandling) {
      return;
    }

    if (authService.isLoggedIn.value) {
      // Fetch fresh profile from backend
      try {
        await authService.getMe();
      } catch (_) {}

      if (isClosed) return;
      if (Get.currentRoute != Routes.splash) {
        debugPrint('[Splash] Route changed to ${Get.currentRoute} — yielding navigation');
        return;
      }

      final user = authService.currentUser.value;
      if (user == null) {
        Get.offAllNamed(Routes.onboarding);
        return;
      }

      if (!user.hasLocation) {
        Get.offAllNamed(Routes.locationAllow);
        return;
      }

      if (user.role == 'helper') {
        // Step 1: Check if basic form is submitted
        if (!user.isHelperFormSubmitted) {
          Get.offAllNamed(Routes.applyAsHelper);
          return;
        }

        // Step 2: Form submitted, check KYC status
        switch (user.helperApplicationStatus) {
          case 'approved':
            Get.offAllNamed(Routes.helperHome);
            break;
          case 'pending_appeal':
            Get.offAllNamed(Routes.applicationPending);
            break;
          case 'rejected':
            Get.offAllNamed(Routes.applicationRejected);
            break;
          case 'pending':
          default:
            if (user.diditStatus == 'In Review') {
              Get.offAllNamed(Routes.applicationPending);
            } else {
              Get.offAllNamed(Routes.helperKycVerification);
            }
            break;
        }
      } else {
        Get.offAllNamed(Routes.home);
      }
    } else {
      Get.offAllNamed(Routes.onboarding);
    }
  }
}
