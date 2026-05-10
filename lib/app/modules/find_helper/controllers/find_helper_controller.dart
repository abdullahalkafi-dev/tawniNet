import 'package:get/get.dart';

class FindHelperController extends GetxController {
  final selectedCategoryIndex = 1.obs;
  final sortBy = 'Nearest'.obs;
  final distanceValue = 10.0.obs;
  final ratingValue = 4.0.obs;
  final isAvailableNow = true.obs;

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
  }

  void setSortBy(String value) {
    sortBy.value = value;
  }

  void clearFilters() {
    selectedCategoryIndex.value = -1;
    sortBy.value = 'Nearest';
    distanceValue.value = 10.0;
    ratingValue.value = 4.0;
    isAvailableNow.value = false;
  }
}
