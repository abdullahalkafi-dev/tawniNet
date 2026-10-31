import 'dart:async';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/widgets/app_dialogs.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/app_config_service.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperHomeController extends GetxController with WidgetsBindingObserver {
  static const _kLastTab = 'helper_last_tab';

  final currentIndex = 0.obs;
  final searchQuery = ''.obs;

  /// First load only (skeleton).
  final isLoading = false.obs;
  final hasLoadedOnce = false.obs;
  final loadFailed = false.obs;

  final nearbyJobs = <HelperJob>[].obs;
  final _subs = <StreamSubscription>[];

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _restoreLastTab();
    _applyDeepLinkArgs();
    _setupSocketListeners();
    try {
      Get.find<RefetchService>().register(RefetchKeys.nearbyJobs, () => fetchNearbyJobs(silent: true));
    } catch (_) {}
    syncOnOpen();
    // Terms changed since the user accepted them? Ask once, after the screen settled.
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isRegistered<AuthService>()) Get.find<AuthService>().promptLegalIfNeeded();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncOnOpen();
    }
  }

  /// When the helper opens the app: one position update (no continuous
  /// sharing outside a job) and the list of jobs around.
  Future<void> syncOnOpen() async {
    fetchNearbyJobs(silent: hasLoadedOnce.value);
    if (Get.isRegistered<LocationService>()) {
      final loc = Get.find<LocationService>();
      if (await loc.checkGpsStatus()) {
        unawaited(loc.refreshPositionOnce());
      }
    }
  }

  /// Kept for the GPS screen that asks the helper to turn the location on.
  Future<void> checkGpsAndSync() => syncOnOpen();

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
      // Make sure the jobs tab is the one showing
      if (tab == null) currentIndex.value = 1;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<HelperJobsController>()) {
          Get.find<HelperJobsController>().setPendingOpenJobId(openJobId);
        }
      });
    }
  }

  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socketService = Get.find<SocketService>();
    _subs.addAll([
      socketService.onNewNearbyJob.listen((data) {
        try {
          final job = HelperJob.fromJson(data);
          final existingIndex = nearbyJobs.indexWhere((j) => j.id == job.id);
          if (existingIndex >= 0) {
            nearbyJobs[existingIndex] = job;
          } else {
            nearbyJobs.insert(0, job);
            AppFeedback.info('${job.title} (${job.price})', title: 'ui_new_job_nearby'.tr);
          }
        } catch (_) {}
      }),
      // Someone else took it (or the client cancelled): it disappears from the list at once.
      socketService.onJobUnavailable.listen((data) {
        final id = data['jobId']?.toString();
        if (id != null) nearbyJobs.removeWhere((j) => j.id == id);
      }),
    ]);
  }

  void changeIndex(int index) {
    currentIndex.value = index;
    Get.find<StorageService>().write(_kLastTab, '$index');
  }

  Future<void> fetchNearbyJobs({bool silent = false}) async {
    if (!hasLoadedOnce.value && !silent) isLoading.value = true;
    try {
      final user = Get.find<AuthService>().currentUser.value;
      final lat = Get.isRegistered<LocationService>() ? Get.find<LocationService>().currentLatitude.value : null;
      final lon = Get.isRegistered<LocationService>() ? Get.find<LocationService>().currentLongitude.value : null;

      final data = await Get.find<JobService>().getNearbyJobs(
        lat: lat ?? user?.latitude,
        lon: lon ?? user?.longitude,
        limit: 30,
      );
      final items = data['docs'] as List? ?? [];
      final jobs = <HelperJob>[];
      for (final e in items) {
        if (e is! Map) continue;
        try {
          jobs.add(HelperJob.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
      nearbyJobs.assignAll(jobs);
      hasLoadedOnce.value = true;
      loadFailed.value = false;
    } catch (e) {
      // A failed refresh never empties the list the helper is looking at.
      if (!hasLoadedOnce.value) loadFailed.value = true;
      if (!silent && hasLoadedOnce.value) {
        AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      }
    } finally {
      if (!isClosed) isLoading.value = false;
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
      Get.toNamed(
        Routes.helperChatDetail,
        arguments: ChatSummary(
          id: conversation.id,
          name: other?.name ?? job.helperName,
          image: other?.avatar ?? job.helperImage,
          otherUserId: job.postedByUserId,
        ),
      );
    }
  }

  void onNotificationTap() {
    Get.toNamed(Routes.helperNotifications);
  }

  /// Accepting a job commits the helper: confirm first, explaining what it costs.
  Future<void> confirmAndAccept(HelperJob job) async {
    final isCash = (job.paymentMethod ?? 'cash') == 'cash';
    final fee = Get.isRegistered<AppConfigService>() ? Get.find<AppConfigService>().feePercentage.value : 20.0;
    final total = job.budget ?? 0;
    final commission = (total * fee / 100);
    final ok = await AppDialogs.confirm(
      title: 'job_confirm_accept_title'.tr,
      message: isCash
          ? 'job_confirm_accept_body_cash'.trParams({
              'commission': commission.toStringAsFixed(commission == commission.roundToDouble() ? 0 : 2),
              'pct': fee.toStringAsFixed(fee == fee.roundToDouble() ? 0 : 1),
            })
          : 'job_confirm_accept_body_online'.tr,
      confirmLabel: 'job_accept'.tr,
    );
    if (!ok) return;
    await acceptJob(job.id);
  }

  Future<void> acceptJob(String jobId) async {
    try {
      await Get.find<JobService>().acceptJob(jobId);
      nearbyJobs.removeWhere((j) => j.id == jobId);
      Get.back();
      AppFeedback.success('job_accepted_success'.tr, title: 'ui_job_accepted'.tr);
      // The accepted job now lives in the helper's job list.
      try {
        Get.find<RefetchService>().invalidateJobPipeline();
      } catch (_) {}
      changeIndex(1);
    } catch (e) {
      // Decide by the server's error code, not by searching the text.
      if (e is ApiException && e.code == 'INSUFFICIENT_BALANCE') {
        _showInsufficientBalanceDialog(e.displayMessage);
      } else {
        AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      }
      // The job may be gone (taken by someone else): refresh the list.
      unawaited(fetchNearbyJobs(silent: true));
    }
  }

  void _showInsufficientBalanceDialog(String message) {
    Get.dialog(
      Builder(builder: (context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ui_recharge_required'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              Text(
                'ui_cash_jobs_require_a_platform_commission_fee'.tr,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('btn_cancel'.tr, style: const TextStyle(color: Colors.grey)),
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
              child: Text('ui_recharge_wallet'.tr),
            ),
          ],
        );
      }),
    );
  }

  List<HelperJob> get filteredJobs {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return nearbyJobs;
    return nearbyJobs
        .where((j) =>
            j.title.toLowerCase().contains(q) ||
            j.helperName.toLowerCase().contains(q) ||
            j.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      s.cancel();
    }
    try {
      Get.find<RefetchService>().unregister(RefetchKeys.nearbyJobs);
    } catch (_) {}
    super.onClose();
  }
}
