import 'package:get/get.dart';
import 'package:awnneaapp/app/services/storage_service.dart';

class RoleService extends GetxService {
  final _role = ''.obs;
  String get role => _role.value;
  bool get isHelper => _role.value == 'helper';
  bool get isUser => _role.value == 'user';
  bool get hasRole => _role.value.isNotEmpty;

  void setUserRole(String role) {
    _role.value = role;
    // Persist to storage
    final storage = Get.find<StorageService>();
    storage.saveRole(role);
  }

  void clearRole() {
    _role.value = '';
  }

  /// Load role from storage on startup
  Future<void> loadPersistedRole() async {
    final storage = Get.find<StorageService>();
    final persisted = await storage.getRole();
    if (persisted != null && persisted.isNotEmpty) {
      _role.value = persisted;
    }
  }
}
