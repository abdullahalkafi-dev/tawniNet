import 'dart:async';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/category_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AwnneaSearchController extends GetxController {
  final searchController = TextEditingController();
  final isSearching = false.obs;
  final isLoadingSuggestions = false.obs;

  final categories = <Category>[].obs;
  final searchResults = <HelperJob>[].obs;
  final suggestions = <String>[].obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _loadCategories() async {
    isLoadingSuggestions.value = true;
    try {
      final categoryService = Get.find<CategoryService>();
      final result = await categoryService.getActiveCategories();
      categories.assignAll(result);
      suggestions.assignAll(result.map((c) => c.name));
    } catch (_) {}
    isLoadingSuggestions.value = false;
  }

  void onSearch(String query) {
    if (query.trim().isEmpty) return;
    isSearching.value = true;
    _searchHelpers(query.trim());
  }

  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length >= 2) {
        isSearching.value = true;
        _searchHelpers(query.trim());
      }
    });
  }

  void onCategoryTap(Category category) {
    searchController.text = category.name;
    isSearching.value = true;
    _searchHelpersByCategory(category.id);
  }

  Future<void> _searchHelpers(String query) async {
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      final api = Get.find<ApiClient>();

      final queryParams = <String, dynamic>{
        'limit': 20,
      };
      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
      }

      // Check if query matches a category name
      final matchedCat = categories.firstWhereOrNull(
        (c) => c.name.toLowerCase().contains(query.toLowerCase()),
      );
      if (matchedCat != null) {
        queryParams['category'] = matchedCat.id;
      }

      final response = await api.get(
        ApiConstants.helpersSearch,
        queryParameters: queryParams,
        fromData: (data) => data,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final items = data['helpers'] as List? ?? [];
        searchResults.assignAll(
          items.map<HelperJob>((e) => HelperJob.fromJson(e as Map<String, dynamic>)).toList(),
        );
      } else {
        searchResults.clear();
      }
    } catch (_) {
      searchResults.clear();
    }
  }

  Future<void> _searchHelpersByCategory(String categoryId) async {
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      final api = Get.find<ApiClient>();

      final queryParams = <String, dynamic>{
        'limit': 20,
        'category': categoryId,
      };
      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
      }

      final response = await api.get(
        ApiConstants.helpersSearch,
        queryParameters: queryParams,
        fromData: (data) => data,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final items = data['helpers'] as List? ?? [];
        searchResults.assignAll(
          items.map<HelperJob>((e) => HelperJob.fromJson(e as Map<String, dynamic>)).toList(),
        );
      } else {
        searchResults.clear();
      }
    } catch (_) {
      searchResults.clear();
    }
  }

  void clearRecent() {
    suggestions.clear();
  }

  void removeRecent(String item) {
    suggestions.remove(item);
  }
}
