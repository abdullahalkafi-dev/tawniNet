import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/awnnea_search_controller.dart';
import '../../home/controllers/home_controller.dart';

class SearchView extends GetView<AwnneaSearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: _buildSearchField(),
      ),
      body: Obx(() {
        if (controller.isSearching.value) {
          return _buildResultsView();
        }
        return _buildRecentView();
      }),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller.searchController,
        autofocus: true,
        onSubmitted: controller.onSearch,
        decoration: InputDecoration(
          hintText: 'Cleaner',
          hintStyle: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          icon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRecentView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent', style: AppStyles.h2.copyWith(fontSize: 18)),
              TextButton(
                onPressed: controller.clearRecent,
                child: Text(
                  'Clean All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.recentSearches.length,
                itemBuilder: (context, index) {
                  final item = controller.recentSearches[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      item,
                      style: AppStyles.bodyLarge.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => controller.removeRecent(item),
                    ),
                    onTap: () {
                      controller.searchController.text = item;
                      controller.onSearch(item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    final homeController = Get.find<HomeController>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppStyles.h2.copyWith(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(text: 'Results for '),
                    TextSpan(
                      text: '"${controller.searchController.text}"',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Text(
                '375 founds',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: homeController.popularServices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final service = homeController.popularServices[index];
                return _buildServiceCard(service);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final homeController = Get.find<HomeController>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  service.image,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFF3F4F6),
                      padding: const EdgeInsets.all(12),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.name,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service.rating} (${service.reviews})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.category,
                      style: AppStyles.bodyMedium.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          service.distance,
                          style: AppStyles.bodyMedium.copyWith(fontSize: 12),
                        ),
                        const Text(' • '),
                        Text(
                          '\$${service.pricePerHour.toStringAsFixed(0)}/hr',
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => homeController.onViewProfile(service.id),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Color(0xFFF3F4F6)),
                      backgroundColor: const Color(0xFFF9FAFB),
                    ),
                    child: Text(
                      'View Profile',
                      style: AppStyles.bodyMedium.copyWith(color: Colors.teal),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => homeController.onChatWithHelper(service.id),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: AppColors.primary.withOpacity(0.6),
                    ),
                    child: const Text('Chat', style: TextStyle(fontSize: 14)),
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
