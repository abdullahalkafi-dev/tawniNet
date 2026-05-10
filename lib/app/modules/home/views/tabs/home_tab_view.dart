import 'package:awnneaapp/app/modules/home/views/widgets/categories_section.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/home_header.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/nearby_helpers.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/popular_services_section.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../../../core/values/app_styles.dart';

class HomeTabView extends GetView<HomeController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const HomeHeader(),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: AppStyles.h1.copyWith(
                fontSize: 32,
                color: const Color(0xFF1F2937),
              ),
              children: [
                const TextSpan(text: 'Hello, '),
                TextSpan(
                  text: 'Alex👋',
                  style: TextStyle(color: Colors.orange[400]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find the best helper around you.',
            style: AppStyles.bodyMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const QuickActions(),
          const SizedBox(height: 24),
          _buildSearchBar(),
          const SizedBox(height: 24),
          const CategoriesSection(),
          const SizedBox(height: 24),
          const NearbyHelpers(),
          const SizedBox(height: 24),
          const PopularServicesSection(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onSubmitted: controller.onSearch,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Search for a service...',
          hintStyle: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
