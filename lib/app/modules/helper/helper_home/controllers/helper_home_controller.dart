import 'dart:async';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperHomeController extends GetxController {
  static const _kLastTab = 'helper_last_tab';

  final currentIndex = 0.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  final nearbyJobs = <HelperJob>[].obs;
  StreamSubscription? _nearbyJobSubscription;

  @override
  void onInit() {
    super.onInit();
    _restoreLastTab();
    _applyDeepLinkArgs();
    fetchNearbyJobs();
    _setupSocketListeners();
  }

  void _restoreLastTab() {
    Get.find<StorageService>().read(_kLastTab).then((raw) {
      if (isClosed) return;
      final tab = int.tryParse(raw ?? '');
      if (tab != null && tab >= 0 && tab < 4) {
        currentIndex.value = tab;
      }
    });
  }

  /// Push deep-link: open jobs tab and optionally auto-open a job by id.
  void _applyDeepLinkArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    final tab = args['tab'];
    if (tab is int && tab >= 0 && tab < 4) {
      currentIndex.value = tab;
    }
    final openJobId = args['openJobId']?.toString();
    if (openJobId != null && openJobId.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<HelperJobsController>()) {
          Get.find<HelperJobsController>().setPendingOpenJobId(openJobId);
        }
      });
    }
  }

  void _setupSocketListeners() {
    if (Get.isRegistered<SocketService>()) {
      final socketService = Get.find<SocketService>();
      _nearbyJobSubscription = socketService.onNewNearbyJob.listen((data) {
        try {
          final job = HelperJob.fromJson(data);
          if (!nearbyJobs.any((j) => j.id == job.id)) {
            nearbyJobs.insert(0, job);
            Get.snackbar(
              'New Job Nearby',
              '${job.title} (${job.price})',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 4),
              backgroundColor: AppColors.primary.withValues(alpha: 0.9),
              colorText: Colors.white,
              icon: const Icon(Icons.work_outline, color: Colors.white),
            );
          }
        } catch (_) {}
      });
    }
  }

  void changeIndex(int index) {
    currentIndex.value = index;
    Get.find<StorageService>().write(_kLastTab, '$index');
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
      final errStr = e.toString().replaceAll('Exception: ', '');
      if (errStr.toLowerCase().contains('insufficient') ||
          errStr.toLowerCase().contains('wallet') ||
          errStr.toLowerCase().contains('balance') ||
          errStr.toLowerCase().contains('commission')) {
        _showInsufficientBalanceDialog(errStr);
      } else {
        AppFeedback.error(errStr);
      }
    }
  }

  void _showInsufficientBalanceDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Recharge Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cash jobs require a platform commission fee (from Settings) debited from your wallet balance upon acceptance. Please recharge your wallet to proceed.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              Get.toNamed(Routes.buyConnects);
            },
            child: const Text('Recharge Wallet'),
          ),
        ],
      ),
    );
  }

  List<HelperJob> get filteredJobs {
    if (searchQuery.value.isEmpty) return nearbyJobs;
    return nearbyJobs
        .where((j) => j.helperName.toLowerCase().contains(searchQuery.value.toLowerCase())
            || j.category.toLowerCase().contains(searchQuery.value.toLowerCase()))
        .toList();
  }

  @override
  void onClose() {
    _nearbyJobSubscription?.cancel();
    super.onClose();
  }
}
