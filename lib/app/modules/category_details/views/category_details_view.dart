import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/widgets/helper_trust_widgets.dart';

class CategoryDetailsView extends StatefulWidget {
  const CategoryDetailsView({super.key});

  @override
  State<CategoryDetailsView> createState() => _CategoryDetailsViewState();
}

class _CategoryDetailsViewState extends State<CategoryDetailsView> {
  late final Category category;
  final helpers = <HelperJob>[].obs;
  final isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    category = Get.arguments as Category;
    _fetchCategoryHelpers();
  }

  Future<void> _fetchCategoryHelpers() async {
    isLoading.value = true;
    try {
      final api = Get.find<ApiClient>();
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      final queryParams = <String, dynamic>{
        'limit': 50,
        'category': category.id,
      };

      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
      }

      final response = await api.get(
        ApiConstants.helpersSearch,
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final helpersList = data['helpers'] as List? ?? [];

        final fetched = helpersList
            .map((h) => HelperJob.fromHelperJson(
                  h is Map ? Map<String, dynamic>.from(h) : <String, dynamic>{},
                ))
            .toList();

        helpers.assignAll(fetched);
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          category.name,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return SkeletonList(count: 5, padding: EdgeInsets.zero, itemBuilder: (_, _) => const HelperCardSkeleton());
                }

                if (helpers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: context.textHintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ui_no_helpers_found_in_this_category'.tr,
                          style: AppStyles.bodyMediumOf(context).copyWith(
                            color: context.textSecondaryColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: helpers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _buildServiceCard(context, helpers[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: TextField(
        style: TextStyle(color: context.textPrimaryColor),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: context.textHintColor),
          hintText: 'ui_search_category_helpers'.trParams({'category': category.name}),
          hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, HelperJob service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(url: service.helperImage, width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            service.helperName,
                            style: AppStyles.bodyLargeOf(context).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (service.isVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    RatingSummary(
                      rating: service.rating,
                      reviewCount: service.reviewCount,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.category,
                      style: AppStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.distance,
                      style: AppStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: context.textHintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service.workPhotos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: WorkPhotoStrip(urls: service.workPhotos),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () {
                      Get.toNamed(
                        Routes.helperProfile,
                        arguments: service.postedByUserId,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: context.borderSubtle),
                      backgroundColor: context.inputFillLight,
                    ),
                    child: Text(
                      'btn_view_profile'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: context.isDarkMode ? AppColors.primary : Colors.teal,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      final messagesController =
                          Get.find<MessagesController>();
                      final conversation = await messagesController
                          .startConversation(service.postedByUserId);
                      if (conversation != null) {
                        final other = conversation.otherParticipant;
                        Get.toNamed(
                          Routes.chatDetail,
                          arguments: ChatSummary(
                            id: conversation.id,
                            name: other?.name ?? service.helperName,
                            image: other?.avatar ?? '',
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'btn_chat'.tr,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
