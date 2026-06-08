import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class ApplyHelperBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplyHelperController>(() => ApplyHelperController());
  }
}
