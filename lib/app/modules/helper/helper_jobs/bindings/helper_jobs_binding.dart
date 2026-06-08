import 'package:get/get.dart';
import '../controllers/helper_jobs_controller.dart';

class HelperJobsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelperJobsController>(() => HelperJobsController());
  }
}
