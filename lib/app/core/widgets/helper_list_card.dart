import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/helper_trust_widgets.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';

/// A helper in a list (Home, nearby, search…): photo, name, rating, category,
/// short bio, work samples, distance and a Chat button.
class HelperListCard extends StatelessWidget {
  final HelperJob job;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const HelperListCard({super.key, required this.job, required this.onTap, required this.onChat});

  @override
  Widget build(BuildContext context) {
    final bool isDuplicate = job.title.trim().toLowerCase() ==
        job.description.trim().toLowerCase();
    final bool showTitle = job.title.trim().isNotEmpty && !isDuplicate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
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
                AppAvatar(url: job.helperImage, name: job.helperName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              job.helperName,
                              style: AppStyles.bodyLargeOf(context).copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (job.isVerified) ...[
                            const SizedBox(width: 4),
                            const VerifiedBadge(compact: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      RatingSummary(
                        rating: job.rating,
                        reviewCount: job.reviewCount,
                        fontSize: 11,
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
                        ? AppColors.primary.withValues(alpha: 0.15)
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
            if (showTitle) ...[
              const SizedBox(height: 12),
              Text(
                job.title,
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
            ] else ...[
              const SizedBox(height: 12),
            ],
            if (job.description.trim().isNotEmpty)
              RichText(
                text: TextSpan(
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: job.description,
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            if (job.workPhotos.isNotEmpty) ...[
              const SizedBox(height: 12),
              WorkPhotoStrip(urls: job.workPhotos),
            ],
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
                    onPressed: onChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'btn_chat'.tr,
                      style: const TextStyle(
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
