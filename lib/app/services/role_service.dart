import 'package:get/get.dart';

class RoleService extends GetxService {
  final _role = ''.obs;
  String get role => _role.value;
  bool get isHelper => _role.value == 'helper';
  bool get isUser => _role.value == 'user';
  bool get hasRole => _role.value.isNotEmpty;

  void setUserRole(String role) {
    _role.value = role;
  }

  void clearRole() {
    _role.value = '';
  }
}
