import 'package:get/get.dart';
import '../controllers/helper_profile_controller.dart';

class HelperProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelperProfileController>(
      () => HelperProfileController(),
    );
  }
}
