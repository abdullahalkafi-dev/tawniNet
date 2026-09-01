import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:get/get.dart';

class HelperJobsController extends GetxController {
  final activeJobs = <dynamic>[].obs;
  final completedJobs = <dynamic>[].obs;
  final cancelledJobs = <dynamic>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    isLoading.value = true;
    try {
      final jobService = Get.find<JobService>();
      final jobs = await jobService.getNearbyJobs();

      final active = <dynamic>[];
      final completed = <dynamic>[];
      final cancelled = <dynamic>[];

      for (var job in jobs) {
        final status = (job['status'] ?? '').toString().toUpperCase();
        if (status == 'COMPLETED') {
          completed.add(job);
        } else if (status == 'CANCELLED') {
          cancelled.add(job);
        } else if (status == 'IN_PROGRESS' || status == 'ASSIGNED') {
          active.add(job);
        }
      }

      activeJobs.assignAll(active);
      completedJobs.assignAll(completed);
      cancelledJobs.assignAll(cancelled);
    } catch (_) {
      // Retain previous list or clear
    } finally {
      isLoading.value = false;
    }
  }

  void onJobTap(dynamic job, String type) {
    if (type == 'active') {
      Get.toNamed(Routes.activeJobDetails, arguments: job);
    } else if (type == 'completed') {
      Get.toNamed(Routes.completedJobDetails, arguments: job);
    } else {
      Get.toNamed(Routes.helperCancelDetails, arguments: job);
    }
  }

  Future<void> cancelJob(String id) async {
    try {
      final jobService = Get.find<JobService>();
      await jobService.updateJobStatus(id, 'cancelled');
      Get.back();
      Get.back();
      Get.snackbar('Cancelled', 'Job has been cancelled',
          snackPosition: SnackPosition.BOTTOM);
      fetchJobs();
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
