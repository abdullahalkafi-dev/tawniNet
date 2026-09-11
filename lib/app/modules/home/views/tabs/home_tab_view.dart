import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/categories_section.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/home_header.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/nearby_helpers.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/popular_services_section.dart';
import 'package:awnneaapp/app/modules/home/views/widgets/quick_actions.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../../../core/values/app_styles.dart';

class HomeTabView extends GetView<HomeController> {
  const HomeTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPullToRefresh(
      onRefresh: controller.refreshData,
      child: SingleChildScrollView(
      primary: false,
      physics: AppAlwaysScrollPhysics,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const HomeHeader(),
          const SizedBox(height: 24),
          Obx(() {
            final user = Get.find<AuthService>().currentUser.value;
            final name = user?.name.split(' ').first ?? 'User';
            return RichText(
              text: TextSpan(
                style: AppStyles.h1Of(context).copyWith(
                  fontSize: 32,
                ),
                children: [
                  TextSpan(text: 'home_hello'.tr),
                  TextSpan(
                    text: '$name👋',
                    style: TextStyle(color: Colors.orange[400]),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'home_find_helper'.tr,
            style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const QuickActions(),
          const SizedBox(height: 24),
          _buildSearchBar(context),
          const SizedBox(height: 24),
          const CategoriesSection(),
          const SizedBox(height: 24),
          const NearbyHelpers(),
          const SizedBox(height: 24),
          const PopularServicesSection(),
          const SizedBox(height: 30),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.search),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IgnorePointer(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: context.textHintColor),
              hintText: 'home_search'.tr,
              hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
