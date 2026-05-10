import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      id: '1',
      helperName: 'John D.',
      helperImage: 'https://i.pravatar.cc/150?u=john',
      timeAgo: '2h ago',
      category: 'Plumbing',
      title: 'Kitchen sink leak repair',
      description:
          'Quickly fix water leaks in your kitchen sink to prevent damage and ensure smooth water flow.',
      distance: '2.1 mi away',
    ),
    HelperJob(
      id: '2',
      helperName: 'Mirza D.',
      helperImage: 'https://i.pravatar.cc/150?u=mirza',
      timeAgo: '1h ago',
      category: 'Cleaning',
      title: 'Deep cleaning for apartment',
      description: 'Looking for a thorough cleaning of a 2-bedroom apartment.',
      distance: '1.1 mi away',
    ),
  ].obs;

  final popularServices = <PopularService>[
    PopularService(
      id: '1',
      name: 'Sophia Carter',
      category: 'Electrician',
      rating: 4.9,
      reviews: 120,
      pricePerHour: 40,
      distance: '0.5 mi',
      image: 'https://i.pravatar.cc/150?u=sophia',
    ),
    PopularService(
      id: '2',
      name: 'Brooklyn Simmons',
      category: 'Barber',
      rating: 4.8,
      reviews: 90,
      pricePerHour: 20,
      distance: '0.5 mi',
      image: 'https://i.pravatar.cc/150?u=brooklyn',
    ),
  ].obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  // Actions
  void onCategorySelected(Category category) {
    print('Category selected: ${category.name}');
    Get.toNamed(Routes.categoryDetails, arguments: category.name);
  }

  void onJobSelected(HelperJob job) {
    print('Job selected: ${job.title}');
    Get.toNamed(Routes.helperProfile);
  }

  void onChatWithHelper(String helperId) {
    print('Starting chat with helper: $helperId');
  }

  void onViewProfile(String helperId) {
    print('Viewing profile for helper: $helperId');
    Get.toNamed(Routes.helperProfile);
  }

  void onSearch(String query) {
    print('Searching for: $query');
    Get.toNamed(Routes.search);
  }

  void onNotificationTap() {
    print('Notification tapped');
  }

  void onFindHelperTap() {
    print('Find Helper tapped');
    Get.toNamed(Routes.findHelper);
  }

  void onPostJobTap() {
    print('Post a job tapped');
    Get.toNamed(Routes.postJob);
  }
}
