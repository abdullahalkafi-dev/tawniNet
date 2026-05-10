import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/home_models.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class NearbyHelpers extends GetView<HomeController> {
  const NearbyHelpers({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nearby Helpers', style: AppStyles.h2.copyWith(fontSize: 20)),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Obx(
          () => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.nearbyJobs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildHelperCard(controller.nearbyJobs[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHelperCard(HelperJob job) {
    return GestureDetector(
      onTap: () => controller.onJobSelected(job),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(job.helperImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.helperName,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        job.timeAgo,
                        style: AppStyles.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.category,
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              job.title,
              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              job.description,
              style: AppStyles.bodyMedium.copyWith(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.distance,
                      style: AppStyles.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () => controller.onChatWithHelper(job.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    child: const Text('Chat', style: TextStyle(fontSize: 13)),
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
