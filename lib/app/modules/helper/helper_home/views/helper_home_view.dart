import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/helper_home_controller.dart';
import 'tabs/helper_home_tab_view.dart';
import 'tabs/helper_jobs_tab_view.dart';
import 'package:awnneaapp/app/modules/helper/helper_messages/views/helper_messages_tab_view.dart';
import 'tabs/helper_profile_tab_view.dart';

class HelperHomeView extends GetView<HelperHomeController> {
  HelperHomeView({super.key});

  final List<Widget> _pages = [
    const HelperHomeTabView(),
    const HelperJobsTabView(),
    const HelperMessagesTabView(),
    const HelperProfileTabView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Obx(() => _pages[controller.currentIndex.value])),
      bottomNavigationBar: Obx(
        () => BottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: context.cardColor,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: context.textHintColor,
          showUnselectedLabels: true,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: 'helper_home_tab'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.work_outline),
              activeIcon: const Icon(Icons.work),
              label: 'helper_jobs_tab'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.message_outlined),
              activeIcon: const Icon(Icons.message),
              label: 'helper_messages_tab'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: 'helper_profile_tab'.tr,
            ),
          ],
        ),
      ),
    );
  }
}
