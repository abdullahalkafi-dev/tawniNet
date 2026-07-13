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
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),
              _buildJobList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(60),
                  )
                : _buildAvatarPlaceholder(60),
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
                  style: AppStyles.h2.copyWith(fontSize: 20),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
              Obx(() {
                final user = Get.find<AuthService>().currentUser.value;
                return Text(
                  user?.address ?? 'No location set',
                  style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ],
          ),
        ),
        GestureDetector(
          onTap: controller.onNotificationTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Icon(Icons.notifications_outlined, color: AppColors.primary, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (val) => controller.searchQuery.value = val,
        style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'helper_search_jobs'.tr,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: const Color(0xFFEEF0F3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
        ),
      ),
    );
  }

  Widget _buildJobList() {
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
                  Icon(Icons.work_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No nearby jobs found',
                    style: AppStyles.bodyLarge.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: AppStyles.bodyMedium.copyWith(color: Colors.grey[400]),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F4F6)),
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
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(Icons.person, color: Colors.grey),
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
                            style: AppStyles.h2.copyWith(fontSize: 16),
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
                    style: AppStyles.bodyMedium.copyWith(fontSize: 13),
                  ),
                ],
                if (job.address != null && job.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bodyMedium.copyWith(
                            fontSize: 12,
                            color: Colors.grey,
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

  Widget _buildAvatarPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF3F4F6),
      padding: EdgeInsets.all(size * 0.3),
      child: SvgPicture.asset(
        'assets/svgs/profile_icon.svg',
        colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
      ),
    );
  }
}
