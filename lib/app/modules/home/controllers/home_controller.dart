import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/category_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:get/get.dart';

import 'package:awnneaapp/app/modules/booking/controllers/booking_controller.dart';
import '../views/all_services_view.dart';

class HomeController extends GetxController {
  static const _kLastTab = 'client_last_tab';

  final currentIndex = 0.obs;

  final categories = <Category>[].obs;
  final nearbyJobs = <HelperJob>[].obs;
  final popularServices = <PopularService>[].obs;

  // True until the first answer arrives: the Home tab shows skeletons, not empty states.
  final isLoadingCategories = true.obs;
  final isLoadingHelpers = true.obs;
  final helpersFailed = false.obs;

  /// "Popular" list filter (a category name, '' = all). Kept here so it survives rebuilds.
  final popularFilter = ''.obs;

  Worker? _locationWorker;

  @override
  void onInit() {
    super.onInit();
    _restoreLastTab();
    _applyDeepLinkArgs();
    Get.find<RefetchService>().register(
      RefetchKeys.categories,
      fetchCategories,
    );
    Get.find<RefetchService>().register(
      RefetchKeys.popularHelpers,
      fetchNearbyHelpers,
    );
    Get.find<RefetchService>().register(
      RefetchKeys.nearbyJobs,
      fetchNearbyHelpers,
    );
    fetchCategories();
    fetchNearbyHelpers();
    // Terms changed since the user accepted them? Ask once, after the screen settled.
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isRegistered<AuthService>()) Get.find<AuthService>().promptLegalIfNeeded();
    });

    // When the user's saved position changes (new address), show helpers around the new place.
    _locationWorker = ever(Get.find<AuthService>().currentUser, (_) {
      final u = Get.find<AuthService>().currentUser.value;
      final key = '${u?.latitude}|${u?.longitude}';
      if (key != _lastLocationKey) {
        _lastLocationKey = key;
        fetchNearbyHelpers();
      }
    });
  }

  String? _lastLocationKey;

  @override
  void onClose() {
    _locationWorker?.dispose();
    Get.find<RefetchService>().unregister(RefetchKeys.categories);
    Get.find<RefetchService>().unregister(RefetchKeys.popularHelpers);
    Get.find<RefetchService>().unregister(RefetchKeys.nearbyJobs);
    super.onClose();
  }

  void _restoreLastTab() {
    final saved = Get.find<StorageService>().read(_kLastTab);
    saved.then((raw) {
      if (isClosed) return;
      final tab = int.tryParse(raw ?? '');
      if (tab != null && tab >= 0 && tab < 4) {
        currentIndex.value = tab;
      }
    });
  }

  /// Deep link: open bookings tab and optionally auto-open a job by id
  void _applyDeepLinkArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    final tab = args['tab'];
    if (tab is int && tab >= 0 && tab < 4) {
      currentIndex.value = tab;
    }
    final jobId = args['jobId']?.toString();
    if (jobId != null && jobId.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<BookingController>()) {
          Get.find<BookingController>().setPendingOpenJobId(jobId);
        }
      });
    }
  }

  // ─── Data Fetching ──────────────────────────────────────

  Future<void> fetchCategories() async {
    if (categories.isEmpty) isLoadingCategories.value = true;
    try {
      final categoryService = Get.find<CategoryService>();
      final result = await categoryService.getActiveCategories();
      categories.assignAll(result);
    } catch (e) {
      // The categories already on screen stay; with none, the Home tab shows a retry card.
      if (kDebugMode) debugPrint('[Home] categories failed: $e');
    } finally {
      if (!isClosed) isLoadingCategories.value = false;
    }
  }

  bool _fetchingHelpers = false;

  Future<void> fetchNearbyHelpers() async {
    // Several refresh keys point here: run once, not three times.
    if (_fetchingHelpers) return;
    _fetchingHelpers = true;
    if (nearbyJobs.isEmpty) isLoadingHelpers.value = true;
    try {
      final api = Get.find<ApiClient>();
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      // One request feeds both lists on the Home tab ("nearby" = the first 10, "popular" = all).
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

        final maps = helpersList
            .map((h) => h is Map ? Map<String, dynamic>.from(h) : <String, dynamic>{})
            .toList();
        final helpers = maps.map(HelperJob.fromHelperJson).toList();

        nearbyJobs.assignAll(helpers.take(10).toList());
        popularServices.assignAll(maps.map(_toPopular).toList());
        helpersFailed.value = false;
      }
    } catch (e) {
      // Keep what is on screen; show the retry state only when there is nothing.
      if (nearbyJobs.isEmpty) helpersFailed.value = true;
      if (kDebugMode) debugPrint('[Home] helpers failed: $e');
    } finally {
      _fetchingHelpers = false;
      if (!isClosed) isLoadingHelpers.value = false;
    }
  }

  Future<void> refreshData() async {
    await Future.wait([
      fetchCategories(),
      fetchNearbyHelpers(),
    ]);
  }

  PopularService _toPopular(Map<String, dynamic> map) {
    final serviceType = map['serviceType'];
    String category = 'ui_general'.tr;
    if (serviceType is Map) {
      final n = localizedCategoryName(serviceType);
      if (n.isNotEmpty) category = n;
    } else if (serviceType is String && serviceType.isNotEmpty) {
      category = serviceType;
    }
    final distKm = map['distanceKm'];
    final area = (map['area'] ?? map['city'] ?? map['address'])?.toString();
    return PopularService(
      id: map['_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'ui_helper'.tr,
      category: category,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviews: (map['reviewCount'] as num?)?.toInt() ?? 0,
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      distance: distKm is num
          ? '${distKm.toStringAsFixed(1)} km'
          : ((area != null && area.isNotEmpty) ? area : 'ui_nearby'.tr),
      image: map['avatar']?.toString() ?? '',
      isVerified: map['isVerified'] == true,
    );
  }

  // ─── Navigation ─────────────────────────────────────────

  void changeIndex(int index) {
    currentIndex.value = index;
    Get.find<StorageService>().write(_kLastTab, '$index');
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
          name: other?.name ?? 'ui_helper'.tr,
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
    Get.toNamed(Routes.notifications);
  }

  void onFindHelperTap() {
    Get.toNamed(Routes.findHelper);
  }

  void onPostJobTap() {
    Get.toNamed(Routes.postJob);
  }
}
