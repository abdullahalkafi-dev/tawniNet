import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:get/get.dart';

class CategoryService {
  late final ApiClient _api;

  CategoryService() {
    _api = Get.find<ApiClient>();
  }

  Future<List<Category>> getActiveCategories() async {
    final response = await _api.get(
      ApiConstants.categories,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      final list = (response.data as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    }

    throw Exception(response.message ?? 'Failed to load categories');
  }
}
