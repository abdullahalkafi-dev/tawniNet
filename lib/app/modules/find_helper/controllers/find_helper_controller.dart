import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/category_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindHelperController extends GetxController {
  final selectedCategoryIndex = 0.obs;
  final sortBy = 'Nearest'.obs;
  final distanceValue = 10.0.obs;
  final ratingValue = 4.0.obs;
  final isAvailableNow = true.obs;

  final categories = <Category>[].obs;
  final helpers = <HelperJob>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final currentPage = 1.obs;
  final totalPages = 1.obs;

  final scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    searchHelpers();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore.value && currentPage.value < totalPages.value) {
        searchHelpers(loadMore: true);
      }
    }
  }

  void _loadCategories() async {
    try {
      final categoryService = Get.find<CategoryService>();
      final result = await categoryService.getActiveCategories();
      if (!isClosed) {
        categories.assignAll(result);
      }
    } catch (_) {}
  }

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
    currentPage.value = 1;
    searchHelpers();
  }

  void setSortBy(String value) {
    sortBy.value = value;
    currentPage.value = 1;
    searchHelpers();
  }

  void updateDistance(double value) {
    distanceValue.value = value;
  }

  void updateRating(double value) {
    ratingValue.value = value;
  }

  void toggleAvailableNow() {
    isAvailableNow.value = !isAvailableNow.value;
  }

  void applyFilters({bool closeScreen = true}) {
    currentPage.value = 1;
    searchHelpers();
    if (closeScreen) Get.back();
  }

  /// Distance slider / in-page filters — stay on this screen.
  void applyFiltersInPlace() => applyFilters(closeScreen: false);

  void clearFilters() {
    selectedCategoryIndex.value = 0;
    sortBy.value = 'Nearest';
    distanceValue.value = 10.0;
    ratingValue.value = 4.0;
    isAvailableNow.value = false;
    currentPage.value = 1;
    searchHelpers();
  }

  Future<void> searchHelpers({bool loadMore = false}) async {
    if (loadMore) {
      if (currentPage.value >= totalPages.value) return;
      isLoadingMore.value = true;
    } else {
      isLoading.value = true;
      helpers.clear();
    }

    try {
      final api = Get.find<ApiClient>();
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      final queryParams = <String, dynamic>{
        'page': loadMore ? currentPage.value + 1 : 1,
        'limit': 20,
      };

      // Add category filter
      if (selectedCategoryIndex.value > 0 &&
          selectedCategoryIndex.value < categories.length) {
        final selectedCat = categories[selectedCategoryIndex.value - 1];
        queryParams['category'] = selectedCat.id;
      }

      // Add location
      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
        // Convert km to meters for backend
        queryParams['maxDistance'] = (distanceValue.value * 1000).toInt();
      }

      final response = await api.get(
        ApiConstants.helpersSearch,
        queryParameters: queryParams,
      );

      if (!isClosed && response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final helpersList = data['helpers'] as List? ?? [];
        final total = data['totalPages'] as int? ?? 1;

        final fetchedHelpers = helpersList.map((h) {
          final map = h is Map ? Map<String, dynamic>.from(h) : <String, dynamic>{};
          final serviceType = map['serviceType'];
          String category = 'General';
          if (serviceType is Map) {
            category = serviceType['name']?.toString() ?? 'General';
          }

          String avatar = '';
          final rawAvatar = map['avatar'];
          if (rawAvatar is String && rawAvatar.isNotEmpty) {
            avatar = rawAvatar;
          }

          return HelperJob(
            id: map['_id']?.toString() ?? '',
            helperName: map['name']?.toString() ?? 'Helper',
            helperImage: avatar,
            postedByUserId: map['_id']?.toString() ?? '',
            timeAgo: _formatDate(map['createdAt']?.toString()),
            category: category,
            title: map['bio']?.toString() ?? 'Available for hire',
            description: map['bio']?.toString() ?? 'Professional helper in your area',
            distance: map['address']?.toString() ?? 'Nearby',
            rating: (map['rating'] as num?)?.toDouble() ?? 0,
            reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        if (loadMore) {
          helpers.addAll(fetchedHelpers);
          currentPage.value++;
        } else {
          helpers.assignAll(fetchedHelpers);
        }
        totalPages.value = total;
      }
    } catch (_) {} finally {
      if (!isClosed) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }

  Future<void> refreshData() async {
    currentPage.value = 1;
    await searchHelpers();
  }
}
