import 'package:get/get.dart';

class ProfileController extends GetxController {
  // Edit Profile fields
  final name = 'Sarah Johnson'.obs;
  final email = 'Sarahjohnson@gmail.com'.obs;
  final phone = '(964) 677-7646'.obs;
  final gender = 'Male'.obs;
  final address = '34076 NW 120th ave'.obs;

  // Notification toggles
  final notificationEnabled = true.obs;
  final soundEnabled = true.obs;
  final vibrateEnabled = false.obs;
  final paymentsEnabled = true.obs;
  final cashbackEnabled = false.obs;
  final appUpdatesEnabled = false.obs;
  final newServiceEnabled = true.obs;

  void updateProfile() {
    print('Profile Updated');
    Get.back();
  }
}
