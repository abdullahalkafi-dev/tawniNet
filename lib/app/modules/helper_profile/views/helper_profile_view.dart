import 'package:awnneaapp/app/core/widgets/review_card.dart';
import 'package:awnneaapp/app/core/widgets/error_retry.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/emoji_picker_panel.dart';
import 'package:awnneaapp/app/core/widgets/helper_trust_widgets.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/helper_profile_controller.dart';

class HelperProfileView extends GetView<HelperProfileController> {
  const HelperProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'helper_details'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const DetailSkeleton();
        }

        final helper = controller.helper.value;
        if (helper == null) {
          return Center(
            child: Text(
              'ui_helper_not_found'.tr,
              style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            ),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 140,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, helper),
                  const SizedBox(height: 24),
                  _buildStats(context, helper),
                  const SizedBox(height: 32),
                  _buildAboutMe(context, helper),
                  const SizedBox(height: 32),
                  _buildPhotos(context, helper),
                  const SizedBox(height: 32),
                  _buildReviews(context),
                ],
              ),
            ),
            _buildBottomChat(context),
          ],
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic helper) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: AppNetworkImage(url: helper.avatar ?? '', width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            helper.name ?? 'ui_helper'.tr,
            style: AppStyles.h1Of(context).copyWith(fontSize: 24),
          ),
          Text(
            helper.categoryName ?? 'ui_general'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 6,
            children: [
              if (helper.isVerified) const VerifiedBadge(),
              RatingSummary(
                rating: helper.rating,
                reviewCount: helper.reviewCount,
                fontSize: 13,
                showReviewWord: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (helper.address != null && helper.address!.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    helper.address!,
                    style: AppStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, dynamic helper) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(
          context,
          helper.experience != null ? '${helper.experience} Yrs' : 'N/A',
          'helper_experience'.tr,
        ),
        _buildStatItem(
          context,
          helper.pricePerHour != null ? '${helper.pricePerHour!.toInt()} MAD' : 'N/A',
          'ui_price_hr'.tr,
        ),
        _buildStatItem(
          context,
          helper.serviceRadius != null ? '${helper.serviceRadius} km' : 'N/A',
          'ui_service_radius'.tr,
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Container(
      width: Get.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppStyles.bodyLargeOf(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMe(BuildContext context, dynamic helper) {
    final bio = helper.bio;
    final hasBio = bio != null && bio.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'label_about_me'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        const SizedBox(height: 12),
        Text(
          hasBio ? bio : 'ui_no_bio_available'.tr,
          style: AppStyles.bodyMediumOf(context).copyWith(
            height: 1.5,
            color: hasBio ? context.textSecondaryColor : context.textHintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotos(BuildContext context, dynamic helper) {
    final rawPhotos = helper.profilePhotos;
    final photoUrls = <String>[];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        final s = p?.toString() ?? '';
        if (s.isNotEmpty && s != 'null') photoUrls.add(s);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'helper_work_photos'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        if (photoUrls.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: context.inputFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Center(
              child: Text(
                'helper_no_work_photos'.tr,
                style: AppStyles.bodyMedium.copyWith(
                  color: context.textHintColor,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Get.to(
                    () => ImageViewerScreen(
                      imageUrls: photoUrls,
                      initialIndex: index.clamp(0, photoUrls.length - 1).toInt(),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppNetworkImage(url: ApiConstants.resolveImageUrl(photoUrls[index]) ??
                        photoUrls[index], fit: BoxFit.cover),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildReviews(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'label_reviews'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        if (controller.isLoadingReviews.value)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: context.inputFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtle),
            ),
            child: const Shimmer(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(height: 12, widthFactor: 0.4),
                    SizedBox(height: 10),
                    SkeletonLine(height: 10),
                    SizedBox(height: 6),
                    SkeletonLine(height: 10, widthFactor: 0.7),
                  ],
                ),
              ),
            ),
          )
        else if (controller.reviewsFailed.value)
          ErrorRetry(
            minHeight: 120,
            onRetry: () => controller.fetchReviews(controller.helper.value?.id ?? ''),
          )
        else if (controller.reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: context.inputFillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtle),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 40,
                    color: context.textHintColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'rating_no_reviews'.tr,
                    style: AppStyles.bodyMediumOf(context).copyWith(
                      color: context.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...controller.reviews.map((r) => _buildReviewCard(context, r)),
      ],
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> review) => ReviewCard(review: review);

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EmojiPickerPanel(
        controller: controller.messageController,
      ),
    );
  }

  Widget _buildBottomChat(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: context.cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.inputFillLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(
                    Icons.sentiment_satisfied_alt_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _showEmojiPicker(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'label_type_message'.tr,
                      hintStyle: TextStyle(color: context.textHintColor),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => controller.sendMessageAndOpenChat(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: controller.sendMessageAndOpenChat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
