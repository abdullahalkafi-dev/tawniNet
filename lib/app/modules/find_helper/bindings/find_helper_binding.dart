import 'package:get/get.dart';
import '../controllers/find_helper_controller.dart';

class FindHelperBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FindHelperController>(
      () => FindHelperController(),
    );
  }
}
