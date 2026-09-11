import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/emoji_picker_panel.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          return const Center(child: CircularProgressIndicator());
        }

        final helper = controller.helper.value;
        if (helper == null) {
          return Center(
            child: Text(
              'Helper not found',
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
                bottom: 100,
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
              child: Image.network(
                helper.avatar ?? '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: context.inputFillLight,
                    padding: const EdgeInsets.all(20),
                    child: SvgPicture.asset(
                      'assets/svgs/profile_icon.svg',
                      colorFilter: ColorFilter.mode(
                        context.textHintColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            helper.name ?? 'Helper',
            style: AppStyles.h1Of(context).copyWith(fontSize: 24),
          ),
          Text(
            helper.categoryName ?? 'General',
            style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
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
          'Experience',
        ),
        _buildStatItem(
          context,
          helper.pricePerHour != null ? '${helper.pricePerHour!.toInt()} MAD' : 'N/A',
          'Price/hr',
        ),
        _buildStatItem(
          context,
          helper.serviceRadius != null ? '${helper.serviceRadius} km' : 'N/A',
          'Service Radius',
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
            color: Colors.black.withOpacity(0.02),
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
          hasBio ? bio : 'No bio available',
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
          'label_photos'.tr,
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
                'No photos yet',
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
                  child: Image.network(
                    ApiConstants.resolveImageUrl(photoUrls[index]) ??
                        photoUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: context.inputFillLight,
                        child: Icon(Icons.broken_image, color: context.textHintColor),
                      );
                    },
                  ),
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
            child: const Center(child: CircularProgressIndicator()),
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
                    'No reviews yet',
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

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> review) {
    final rating = ((review['rating'] as num?) ?? 0).round().clamp(0, 5);
    final name = (review['reviewerName'] ?? 'Client').toString();
    final avatar = (review['reviewerAvatar'] ?? '').toString();
    final comment = (review['comment'] ?? '').toString();
    final date = (review['date'] ?? '').toString();
    final resolvedAvatar = ApiConstants.resolveImageUrl(avatar) ?? avatar;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  resolvedAvatar,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: context.inputFillLight,
                    child: Icon(Icons.person, size: 18, color: context.textHintColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: context.textHintColor),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: AppStyles.bodyMediumOf(context).copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
    );
  }
}
