import 'package:get/get.dart';
import '../controllers/awnnea_search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AwnneaSearchController>(
      () => AwnneaSearchController(),
    );
  }
}
