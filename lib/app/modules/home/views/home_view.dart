import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../booking/views/booking_view.dart';
import '../../messages/views/messages_view.dart';
import '../../profile/views/profile_view.dart';
import 'tabs/home_tab_view.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final List<Widget> _pages = [
    const HomeTabView(),
    const BookingView(),
    const MessagesView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Obx(() => Text(_getTitle(controller.currentIndex.value))),
      // ),
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
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Booking',
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

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Booking';
      case 2:
        return 'Messages';
      case 3:
        return 'Profile';
      default:
        return 'Home';
    }
  }
}
