import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class NearbyHelpersView extends GetView<HomeController> {
  const NearbyHelpersView({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedFilter = 'All'.obs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Nearby Helpers',
          style: AppStyles.h2.copyWith(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search for nearby helper.....',
                  hintStyle: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Obx(
                () => Row(
                  children: [
                    _buildFilterChip('All', selectedFilter),
                    _buildFilterChip('Cleaning', selectedFilter),
                    _buildFilterChip('Repairing', selectedFilter),
                    _buildFilterChip('Painting', selectedFilter),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, RxString selectedFilter) {
    bool isSelected = selectedFilter.value == label;
    return GestureDetector(
      onTap: () => selectedFilter.value = label,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF5AB9A7).withOpacity(0.5),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF5AB9A7),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
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
          border: Border.all(color: Colors.grey[150] ?? const Color(0xFFF3F4F6)),
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
                        color: const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/svgs/profile_icon.svg',
                          colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
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
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.timeAgo,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
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
                    color: const Color(0xFFE5F7F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    job.category,
                    style: AppStyles.bodyMedium.copyWith(
                      color: const Color(0xFF5AB9A7),
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
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: const Color(0xFF4B5563),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      job.distance,
                      style: AppStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
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
