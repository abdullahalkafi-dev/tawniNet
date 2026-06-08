import 'package:awnneaapp/app/core/values/app_colors.dart';
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
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
