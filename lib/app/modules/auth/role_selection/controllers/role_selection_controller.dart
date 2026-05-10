import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:get/get.dart';

class RoleSelectionController extends GetxController {
  void selectUser() {
    Get.toNamed(Routes.login);
  }

  void selectHelper() {
    Get.toNamed(Routes.login);
  }
}
