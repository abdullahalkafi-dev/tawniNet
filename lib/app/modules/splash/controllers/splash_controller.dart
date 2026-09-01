import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (isClosed) return;

    final authService = Get.find<AuthService>();

    if (authService.isLoggedIn.value) {
      // Fetch fresh profile from backend
      try {
        await authService.getMe();
      } catch (_) {}

      if (isClosed) return;

      final user = authService.currentUser.value;
      if (user == null) {
        Get.offAllNamed(Routes.onboarding);
        return;
      }

      if (user.role == 'helper') {
        // Check application status
        switch (user.helperApplicationStatus) {
          case 'approved':
            Get.offAllNamed(Routes.helperHome);
            break;
          case 'pending':
          case 'pending_appeal':
            Get.offAllNamed(Routes.applicationPending);
            break;
          case 'rejected':
            Get.offAllNamed(Routes.applicationRejected);
            break;
          default: // null — no application yet
            Get.offAllNamed(Routes.applyAsHelper);
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
