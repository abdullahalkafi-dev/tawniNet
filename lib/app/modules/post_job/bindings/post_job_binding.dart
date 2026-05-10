import 'package:get/get.dart';
import '../controllers/post_job_controller.dart';

class PostJobBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostJobController>(
      () => PostJobController(),
    );
  }
}
