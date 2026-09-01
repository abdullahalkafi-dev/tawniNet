import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';

class HelperHomeTabView extends GetView<HelperHomeController> {
  const HelperHomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildSearchBar(context),
              const SizedBox(height: 20),
              _buildJobList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Obx(() {
          final user = Get.find<AuthService>().currentUser.value;
          final avatar = user?.avatar;
          return ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: avatar != null && avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context, 60),
                  )
                : _buildAvatarPlaceholder(context, 60),
          );
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final user = Get.find<AuthService>().currentUser.value;
                return Text(
                  user?.name ?? 'Helper',
                  style: AppStyles.h2Of(context).copyWith(fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              Obx(() {
                final user = Get.find<AuthService>().currentUser.value;
                return Text(
                  user?.address ?? 'No location set',
                  style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: controller.onNotificationTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        style: GoogleFonts.inter(fontSize: 15, color: context.textPrimaryColor),
        decoration: InputDecoration(
          hintText: 'helper_search_jobs'.tr,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: context.textHintColor,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: context.inputFillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: context.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: context.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          prefixIcon: Icon(Icons.search, color: context.textHintColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildJobList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.filteredJobs.isEmpty) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 400),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outline, size: 60, color: context.textHintColor),
                  const SizedBox(height: 16),
                  Text(
                    'No nearby jobs found',
                    style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        children: controller.filteredJobs.map((job) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (job.helperImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          job.helperImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: context.inputFillLight,
                            child: Icon(Icons.person, color: context.textHintColor),
                          ),
                        ),
                      ),
                    if (job.helperImage.isNotEmpty) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.helperName,
                            style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                          ),
                          if (job.category.isNotEmpty)
                            Text(
                              job.category,
                              style: AppStyles.bodyMedium.copyWith(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (job.bio != null && job.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    job.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
                  ),
                ],
                if (job.address != null && job.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.orange[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodyMedium.copyWith(
                            fontSize: 12,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => controller.onJobDetails(job),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'helper_details_btn'.tr,
                          style: AppStyles.buttonText.copyWith(color: AppColors.primary, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.onJobChat(job),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'btn_chat'.tr,
                          style: AppStyles.buttonText.copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildAvatarPlaceholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      color: context.inputFillLight,
      padding: EdgeInsets.all(size * 0.3),
      child: SvgPicture.asset(
        'assets/svgs/profile_icon.svg',
        colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
      ),
    );
  }
}
