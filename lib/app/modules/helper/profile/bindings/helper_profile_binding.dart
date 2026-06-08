import 'package:get/get.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';

class HelperProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelperHomeController>(() => HelperHomeController());
  }
}
