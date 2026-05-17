import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Import the new views
import '../views/all_services_view.dart';
import '../views/notifications_view.dart';

class HomeController extends GetxController {
  final currentIndex = 0.obs;

  // Mock Data
  final categories = <Category>[
    Category(
      id: '1',
      name: 'Carrying',
      icon: Icons.inventory_2_outlined,
      color: Colors.orange,
    ),
    Category(
      id: '2',
      name: 'Cleaning',
      icon: Icons.home_repair_service_outlined,
      color: Colors.yellow,
    ),
    Category(
      id: '3',
      name: 'Electrician',
      icon: Icons.bolt,
      color: Colors.purple,
    ),
    Category(
      id: '4',
      name: 'Barber',
      icon: Icons.content_cut,
      color: Colors.red,
    ),
    Category(
      id: '5',
      name: 'Floor',
      icon: Icons.format_paint_outlined,
      color: Colors.teal,
    ),
    Category(
      id: '6',
      name: 'Shifting',
      icon: Icons.local_shipping_outlined,
      color: Colors.amber,
    ),
    Category(
      id: '7',
      name: 'Garden',
      icon: Icons.opacity_outlined,
      color: Colors.orangeAccent,
    ),
    Category(
      id: '8',
      name: 'Shifting',
      icon: Icons.directions_bus_outlined,
      color: Colors.blue,
    ),
  ].obs;

  final nearbyJobs = <HelperJob>[
    HelperJob(
      id: 'job1',
      helperName: 'John D.',
      helperImage: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop',
      timeAgo: '2h ago',
      category: 'Plumbing',
      title: 'Kitchen sink leak repair',
      description:
          'Quickly fix water leaks in your kitchen sink to prevent damage and ensure smooth water flow. Read More',
      distance: '2.1 mi away',
    ),
    HelperJob(
      id: 'job2',
      helperName: 'Mirza D.',
      helperImage: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?q=80&w=200&auto=format&fit=crop',
      timeAgo: '1h ago',
      category: 'Cleaning',
      title: 'Deep cleaning for apartment',
      description: 'Looking for a thorough cleaning of a 2-bedroom apartment. Read More',
      distance: '1.1 mi away',
    ),
    HelperJob(
      id: 'job3',
      helperName: 'Kafi Al.',
      helperImage: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=200&auto=format&fit=crop',
      timeAgo: '4h ago',
      category: 'Barber',
      title: 'The Urban Barber',
      description: 'Looking for a fresh cut and beard trim styling. Read More',
      distance: '0.5 mi away',
    ),
  ].obs;

  final popularServices = <PopularService>[
    PopularService(
      id: 'srv1',
      name: 'Sophia Carter',
      category: 'Electrician',
      rating: 4.9,
      reviews: 120,
      pricePerHour: 40,
      distance: '0.5 mi',
      image: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=200&auto=format&fit=crop',
    ),
    PopularService(
      id: 'srv2',
      name: 'Sophia Carter',
      category: 'Master Electrician',
      rating: 4.9,
      reviews: 120,
      pricePerHour: 40,
      distance: '0.5 mi',
      image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop',
    ),
    PopularService(
      id: 'srv3',
      name: 'Brooklyn Simmons',
      category: 'Barber',
      rating: 4.6,
      reviews: 12,
      pricePerHour: 20,
      distance: '0.5 mi',
      image: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?q=80&w=200&auto=format&fit=crop',
    ),
    PopularService(
      id: 'srv4',
      name: 'Jenny Wilson',
      category: 'Cleaning',
      rating: 4.5,
      reviews: 20,
      pricePerHour: 15,
      distance: '0.5 mi',
      image: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
    ),
  ].obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  // Actions
  void onCategorySelected(Category category) {
    Get.toNamed(Routes.categoryDetails, arguments: category.name);
  }

  void onViewAllCategories() {
    Get.to(() => const AllServicesView());
  }

  void onJobSelected(HelperJob job) {
    Get.toNamed(Routes.helperProfile);
  }

  void onChatWithHelper(String helperId) {
    String name = 'Helper';
    String image = 'https://i.pravatar.cc/150';

    final job = nearbyJobs.firstWhereOrNull((element) => element.id == helperId);
    if (job != null) {
      name = job.helperName;
      image = job.helperImage;
    } else {
      final service = popularServices.firstWhereOrNull((element) => element.id == helperId);
      if (service != null) {
        name = service.name;
        image = service.image;
      }
    }

    Get.toNamed(
      Routes.chatDetail,
      arguments: ChatSummary(
        id: helperId,
        name: name,
        image: image,
        lastMessage: 'How can I help you today?',
        time: 'Now',
        unreadCount: 0,
        isOnline: true,
      ),
    );
  }

  void onViewProfile(String helperId) {
    Get.toNamed(Routes.helperProfile);
  }

  void onSearch(String query) {
    Get.toNamed(Routes.search);
  }

  void onNotificationTap() {
    Get.to(() => const NotificationsView());
  }

  void onFindHelperTap() {
    Get.toNamed(Routes.findHelper);
  }

  void onPostJobTap() {
    Get.toNamed(Routes.postJob);
  }
}
