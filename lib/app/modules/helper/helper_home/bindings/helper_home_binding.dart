import 'package:get/get.dart';
import '../controllers/helper_home_controller.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/profile/controllers/profile_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';

class HelperHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelperHomeController>(() => HelperHomeController());
    Get.lazyPut<HelperJobsController>(() => HelperJobsController());
    Get.lazyPut<MessagesController>(() => MessagesController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
