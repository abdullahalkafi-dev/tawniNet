import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/data/models/helper_models.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';

class HelperHomeController extends GetxController {
  final currentIndex = 0.obs;
  final searchQuery = ''.obs;

  final helperName = 'Al Jabir'.obs;
  final helperLocation = 'Manchester'.obs;
  final helperAvatar = 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200'.obs;

  final jobListings = <HelperJobListing>[
    HelperJobListing(id: '1', title: 'Plumber', price: 'MAD 25', distance: '2km away', category: 'Plumber'),
    HelperJobListing(id: '2', title: 'House Cleaning', price: 'MAD 25', distance: '2km away', category: 'Cleaning'),
    HelperJobListing(id: '3', title: 'Barber', price: 'MAD 25', distance: '2km away', category: 'Barber'),
    HelperJobListing(id: '4', title: 'Electrician', price: 'MAD 25', distance: '2km away', category: 'Electrician'),
    HelperJobListing(id: '5', title: 'Painter', price: 'MAD 25', distance: '2km away', category: 'Painter'),
  ].obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  void onJobDetails(HelperJobListing job) {
    Get.toNamed(Routes.helperJobDetails, arguments: job);
  }

  void onJobChat(HelperJobListing job) {
    Get.toNamed(Routes.helperChatDetail, arguments: ChatSummary(
      id: job.id,
      name: job.title,
      image: 'https://i.pravatar.cc/150?u=${job.id}',
      lastMessage: '',
      time: 'Now',
      unreadCount: 0,
      isOnline: true,
    ));
  }

  void onNotificationTap() {
    Get.toNamed(Routes.helperNotifications);
  }

  List<HelperJobListing> get filteredJobs {
    if (searchQuery.value.isEmpty) return jobListings;
    return jobListings
        .where((j) => j.title.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }
}
