import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:get/get.dart';

class HelperHomeController extends GetxController {
  final currentIndex = 0.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  final nearbyJobs = <HelperJob>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchNearbyJobs();
  }

  void changeIndex(int index) {
    currentIndex.value = index;
  }

  Future<void> fetchNearbyJobs() async {
    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      final api = Get.find<ApiClient>();

      final queryParams = <String, dynamic>{
        'limit': 20,
      };
      if (user?.latitude != null && user?.longitude != null) {
        queryParams['lat'] = user!.latitude;
        queryParams['lon'] = user.longitude;
      }

      final response = await api.get(
        ApiConstants.jobsNearby,
        queryParameters: queryParams,
        fromData: (data) => data,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final items = data['docs'] as List? ?? [];
        nearbyJobs.assignAll(
          items.map<HelperJob>((e) => HelperJob.fromJson(e as Map<String, dynamic>)).toList(),
        );
      } else {
        nearbyJobs.clear();
      }
    } catch (_) {
      nearbyJobs.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await fetchNearbyJobs();
  }

  void onJobDetails(HelperJob job) {
    Get.toNamed(Routes.helperJobDetails, arguments: job);
  }

  Future<void> onJobChat(HelperJob job) async {
    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(job.postedByUserId);
    if (conversation != null) {
      final other = conversation.otherParticipant;
      Get.toNamed(Routes.helperChatDetail, arguments: ChatSummary(
        id: conversation.id,
        name: other?.name ?? job.helperName,
        image: other?.avatar ?? job.helperImage,
      ));
    }
  }

  void onNotificationTap() {
    Get.toNamed(Routes.helperNotifications);
  }

  Future<void> acceptJob(String jobId) async {
    try {
      final jobService = Get.find<JobService>();
      await jobService.acceptJob(jobId);
      Get.back();
      Get.snackbar('Job Accepted', 'Job accepted successfully!', snackPosition: SnackPosition.BOTTOM);
      refreshData();
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''), snackPosition: SnackPosition.BOTTOM);
    }
  }

  List<HelperJob> get filteredJobs {
    if (searchQuery.value.isEmpty) return nearbyJobs;
    return nearbyJobs
        .where((j) => j.helperName.toLowerCase().contains(searchQuery.value.toLowerCase())
            || j.category.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }
}
