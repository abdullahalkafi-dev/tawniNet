import 'package:get/get.dart';

class LocationController extends GetxController {
  final searchQuery = ''.obs;
  final searchResults = <String>[].obs;

  void onAllowLocation() {
    Get.toNamed('/apply-as-helper');
  }

  void onEnterManually() {
    Get.toNamed('/manual-location');
  }

  void onUseCurrentLocation() {
    Get.toNamed('/apply-as-helper');
  }

  void searchLocation(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }
    searchResults.value = ['London', 'Morocco', 'Manchester', 'New York']
        .where((loc) => loc.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void selectLocation(String location) {
    Get.toNamed('/apply-as-helper');
  }

  void goBack() {
    Get.back();
  }
}
