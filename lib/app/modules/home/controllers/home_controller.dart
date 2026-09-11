import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/category_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:get/get.dart';

import '../views/all_services_view.dart';
import '../views/notifications_view.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  final categories = <Category>[].obs;
  final nearbyJobs = <HelperJob>[].obs;
  final popularServices = <PopularService>[].obs;

  final isLoadingCategories = false.obs;
  final isLoadingHelpers = false.obs;

  @override
  void onInit() {
    super.onInit();
    Get.find<RefetchService>().register(
      RefetchKeys.categories,
      fetchCategories,
    );
    Get.find<RefetchService>().register(
      RefetchKeys.popularHelpers,
      fetchPopularServices,
    );
    Get.find<RefetchService>().register(
      RefetchKeys.nearbyJobs,
      fetchNearbyHelpers,
    );
    fetchCategories();
    fetchNearbyHelpers();
    fetchPopularServices();
  }

  @override
  void onClose() {
    Get.find<RefetchService>().unregister(RefetchKeys.categories);
    Get.find<RefetchService>().unregister(RefetchKeys.popularHelpers);
    Get.find<RefetchService>().unregister(RefetchKeys.nearbyJobs);
    super.onClose();
  }

  // ─── Data Fetching ──────────────────────────────────────

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final categoryService = Get.find<CategoryService>();
      final result = await categoryService.getActiveCategories();
      categories.assignAll(result);
    } catch (_) {} finally {
      if (!isClosed) isLoadingCategories.value = false;
    }
  }

  Future<void> fetchNearbyHelpers() async {
    isLoadingHelpers.value = true;
    try {
      final api = Get.find<ApiClient>();
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      final queryParams = <String, dynamic>{
        'limit': 10,
      };

      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
      }

      final response = await api.get(
        ApiConstants.helpersSearch,
        queryParameters: queryParams,
      );

      if (!isClosed && response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final helpersList = data['helpers'] as List? ?? [];

        final helpers = helpersList.map((h) {
          final serviceType = h['serviceType'];
          String category = 'General';
          if (serviceType is Map) {
            category = serviceType['name'] as String? ?? 'General';
          }

          String avatar = 'https://i.pravatar.cc/150';
          if (h['avatar'] != null && (h['avatar'] as String).isNotEmpty) {
            avatar = h['avatar'];
          }

          return HelperJob(
            id: h['_id'] ?? '',
            helperName: h['name'] ?? 'Helper',
            helperImage: avatar,
            postedByUserId: h['_id'] ?? '',
            timeAgo: _formatDate(h['createdAt']),
            category: category,
            title: h['bio'] ?? 'Available for hire',
            description: h['bio'] ?? 'Professional helper in your area',
            distance: h['address'] ?? 'Nearby',
          );
        }).toList();

        nearbyJobs.assignAll(helpers);
      }
    } catch (_) {} finally {
      if (!isClosed) isLoadingHelpers.value = false;
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
    await Future.wait([
      fetchCategories(),
      fetchNearbyHelpers(),
      fetchPopularServices(),
    ]);
  }

  // ─── Popular Services ──────────────────────────────────

  Future<void> fetchPopularServices() async {
    try {
      final api = Get.find<ApiClient>();
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      final queryParams = <String, dynamic>{
        'limit': 20,
      };
      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
      }

      final response = await api.get(
        ApiConstants.helpersSearch,
        queryParameters: queryParams,
      );

      if (!isClosed && response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final helpersList = data['helpers'] as List? ?? [];

        final services = helpersList.map((h) {
          final map = h is Map ? Map<String, dynamic>.from(h) : <String, dynamic>{};
          final serviceType = map['serviceType'];
          String category = 'General';
          if (serviceType is Map) {
            category = serviceType['name']?.toString() ?? 'General';
          } else if (serviceType is String) {
            category = serviceType;
          }

          String avatar = '';
          final rawAvatar = map['avatar'];
          if (rawAvatar is String && rawAvatar.isNotEmpty) {
            avatar = rawAvatar;
          }

          final ratingRaw = map['rating'];
          final rating = ratingRaw is num
              ? ratingRaw.toDouble()
              : (double.tryParse(ratingRaw?.toString() ?? '') ?? 0);
          final reviewRaw = map['reviewCount'];
          final reviews = reviewRaw is num
              ? reviewRaw.toInt()
              : (int.tryParse(reviewRaw?.toString() ?? '') ?? 0);

          return PopularService(
            id: map['_id']?.toString() ?? '',
            name: map['name']?.toString() ?? 'Helper',
            category: category,
            rating: rating,
            reviews: reviews,
            pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
            distance: map['address']?.toString() ?? 'Nearby',
            image: avatar,
          );
        }).toList();

        popularServices.assignAll(services);
      }
    } catch (_) {}
  }

  // ─── Navigation ─────────────────────────────────────────

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  void onCategorySelected(Category category) {
    Get.toNamed(Routes.categoryDetails, arguments: category);
  }

  void onViewAllCategories() {
    Get.to(() => const AllServicesView());
  }

  void onJobSelected(HelperJob job) {
    Get.toNamed(Routes.helperProfile, arguments: job.postedByUserId);
  }

  Future<void> onChatWithHelper(String helperId) async {
    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(helperId);
    if (conversation != null) {
      final other = conversation.otherParticipant;
      Get.toNamed(
        Routes.chatDetail,
        arguments: ChatSummary(
          id: conversation.id,
          name: other?.name ?? 'Helper',
          image: other?.avatar ?? '',
        ),
      );
    }
  }

  void onViewProfile(String helperId) {
    Get.toNamed(Routes.helperProfile, arguments: helperId);
  }

  void onSearch(String query) {
    Get.toNamed(Routes.search);
  }

  void onNotificationTap() {
    Get.to(() => const NotificationsView());
  }

  void onFindHelperTap() {
    Get.toNamed(Routes.findHelper);
  }

  void onPostJobTap() {
    Get.toNamed(Routes.postJob);
  }
}
