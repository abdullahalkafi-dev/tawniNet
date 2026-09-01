import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../data/models/home_models.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../nearby_helpers_view.dart';

class NearbyHelpers extends GetView<HomeController> {
  const NearbyHelpers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nearby Helpers',
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 18,
              ),
            ),
            TextButton(
              onPressed: () => Get.to(() => const NearbyHelpersView()),
              child: Text(
                'View All',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.nearbyJobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildHelperCard(context, controller.nearbyJobs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHelperCard(BuildContext context, HelperJob job) {
    return GestureDetector(
      onTap: () => controller.onJobSelected(job),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    job.helperImage,
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        color: context.inputFillLight,
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/svgs/profile_icon.svg',
                          colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.helperName,
                        style: AppStyles.bodyLargeOf(context).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.timeAgo,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 11,
                          color: context.textHintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.primary.withOpacity(0.15)
                        : const Color(0xFFE5F7F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.category,
                    style: AppStyles.bodyMedium.copyWith(
                      color: context.isDarkMode ? AppColors.primary : const Color(0xFF5AB9A7),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              job.title,
              style: AppStyles.bodyLargeOf(context).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: AppStyles.bodyMediumOf(context).copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: job.description.replaceAll(' Read More', ''),
                  ),
                  if (job.description.contains('Read More'))
                    const TextSpan(
                      text: ' Read More',
                      style: TextStyle(
                        color: Color(0xFF5AB9A7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          job.distance,
                          style: AppStyles.bodyMedium.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => controller.onChatWithHelper(job.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
