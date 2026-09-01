import 'package:get/get.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';
import 'package:awnneaapp/app/modules/helper/settings/controllers/customer_service_controller.dart';

class HelperSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelperHomeController>(() => HelperHomeController());
    Get.lazyPut<CustomerServiceController>(() => CustomerServiceController());
  }
}
