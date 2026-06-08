import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:get/get.dart';

class RoleSelectionController extends GetxController {
  void selectUser() {
    Get.find<RoleService>().setUserRole('user');
    Get.toNamed(Routes.login, arguments: {'role': 'user'});
  }

  void selectHelper() {
    Get.find<RoleService>().setUserRole('helper');
    Get.toNamed(Routes.login, arguments: {'role': 'helper'});
  }
}
