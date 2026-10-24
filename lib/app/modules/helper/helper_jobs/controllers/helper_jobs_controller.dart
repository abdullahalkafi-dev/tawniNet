import 'dart:async';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:get/get.dart';

class HelperJobsController extends GetxController {
  final activeJobs = <dynamic>[].obs;
  final completedJobs = <dynamic>[].obs;
  final cancelledJobs = <dynamic>[].obs;
  final isLoading = false.obs;

  String? _pendingOpenJobId;
  StreamSubscription? _jobCancelledSub;
  StreamSubscription? _jobCompletedSub;

  @override
  void onInit() {
    super.onInit();
    try {
      Get.find<RefetchService>().register(
        RefetchKeys.helperJobs,
        () => fetchJobs(),
      );
    } catch (_) {}
    _setupSocketListeners();
    fetchJobs();
  }

  @override
  void onClose() {
    _jobCancelledSub?.cancel();
    _jobCompletedSub?.cancel();
    try {
      Get.find<RefetchService>().unregister(RefetchKeys.helperJobs);
    } catch (_) {}
    super.onClose();
  }

  /// Queue a job id to auto-open after the next successful fetch (push deep-link).
  void setPendingOpenJobId(String? jobId) {
    if (jobId == null || jobId.isEmpty) return;
    _pendingOpenJobId = jobId;
    if (activeJobs.isNotEmpty || completedJobs.isNotEmpty || cancelledJobs.isNotEmpty) {
      _openPendingJobDetails();
    }
  }

  Future<void>? _fetchInFlight;

  /// Safe for pull-to-refresh: joins an in-flight fetch instead of stacking.
  Future<void> fetchJobs({bool userInitiated = false}) {
    final existing = _fetchInFlight;
    if (existing != null) return existing;
    final future = _fetchJobsImpl(userInitiated: userInitiated);
    _fetchInFlight = future;
    return future.whenComplete(() {
      if (identical(_fetchInFlight, future)) {
        _fetchInFlight = null;
      }
    });
  }

  Future<void> _fetchJobsImpl({bool userInitiated = false}) async {
    isLoading.value = true;
    try {
      final jobService = Get.find<JobService>();
      final res = await jobService.getMyAssignedJobs();

      activeJobs.assignAll(res['active'] ?? []);
      completedJobs.assignAll(res['completed'] ?? []);
      cancelledJobs.assignAll(res['cancelled'] ?? []);

      // Automatically sync active job ID to location service
      if (Get.isRegistered<LocationService>()) {
        final loc = Get.find<LocationService>();
        if (activeJobs.isNotEmpty) {
          final first = activeJobs.first;
          final jobId = (first is Map ? (first['id'] ?? first['_id']) : null)?.toString();
          if (jobId != null && jobId.isNotEmpty) {
            loc.setActiveJobId(jobId);
          }
        } else {
          loc.setActiveJobId(null);
        }
      }

      _openPendingJobDetails();
    } catch (e) {
      if (!isClosed &&
          (userInitiated ||
              (activeJobs.isEmpty &&
                  completedJobs.isEmpty &&
                  cancelledJobs.isEmpty))) {
        AppFeedback.error(
          e.toString().replaceAll('Exception: ', '').isEmpty
              ? 'ui_could_not_load_jobs_pull_down_to'.tr
              : e.toString().replaceAll('Exception: ', ''),
          title: 'helper_my_job'.tr,
        );
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  void _openPendingJobDetails() {
    final id = _pendingOpenJobId;
    if (id == null || id.isEmpty) return;
    _pendingOpenJobId = null;

    Map? match;
    String type = 'active';

    bool matches(dynamic job) {
      try {
        final map = Map<String, dynamic>.from(job as Map);
        final jid = (map['id'] ?? map['_id'] ?? '').toString();
        return jid == id;
      } catch (_) {
        return false;
      }
    }

    for (final job in activeJobs) {
      if (matches(job)) {
        match = Map<String, dynamic>.from(job as Map);
        type = 'active';
        break;
      }
    }
    match ??= () {
      for (final job in completedJobs) {
        if (matches(job)) {
          type = 'completed';
          return Map<String, dynamic>.from(job as Map);
        }
      }
      for (final job in cancelledJobs) {
        if (matches(job)) {
          type = 'cancelled';
          return Map<String, dynamic>.from(job as Map);
        }
      }
      return null;
    }();

    if (match == null) return;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (Get.isRegistered<HelperJobsController>()) {
        onJobTap(match, type);
      }
    });
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

  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    _jobCancelledSub = socket.onJobCancelled.listen((data) {
      final jid = (data['id'] ?? data['_id'])?.toString();
      if (jid != null && jid.isNotEmpty) {
        final reason = (data['cancellationReason'] ?? data['reason'] ?? 'Cancelled by client').toString();
        final title = (data['title'] ?? 'Job').toString();
        final wasActive = activeJobs.any((item) {
          if (item is! Map) return false;
          final id = (item['id'] ?? item['_id'] ?? '').toString();
          return id == jid;
        });

        // The helper receives this event for their own cancellations too.
        final cancelledByRaw = data['cancelledBy'];
        final cancelledBy = (cancelledByRaw is Map
                ? (cancelledByRaw['_id'] ?? cancelledByRaw['id'])
                : cancelledByRaw)
            ?.toString();
        final myId = Get.isRegistered<AuthService>()
            ? Get.find<AuthService>().currentUser.value?.id
            : null;
        final cancelledByMe = cancelledBy != null && cancelledBy == myId;

        _moveJobToCancelledLocally(jid, reason: reason, rawJob: data);

        if (wasActive && !cancelledByMe) {
          AppFeedback.info('"$title" was cancelled by the client.', title: 'cancel_job_cancelled'.tr);
        }
        _invalidatePipeline().catchError((_) {});
      }
    });

    _jobCompletedSub = socket.onJobCompleted.listen((_) {
      _invalidatePipeline().catchError((_) {});
    });
  }

  void _moveJobToCancelledLocally(String id, {String reason = 'Cancelled', dynamic rawJob}) {
    if (id.isEmpty) return;
    Map<String, dynamic>? targetJob;

    for (var i = 0; i < activeJobs.length; i++) {
      final job = activeJobs[i];
      if (job is! Map) continue;
      final map = Map<String, dynamic>.from(job);
      final jid = (map['id'] ?? map['_id'] ?? '').toString();
      if (jid == id) {
        targetJob = map;
        activeJobs.removeAt(i);
        break;
      }
    }

    if (targetJob == null && rawJob is Map) {
      targetJob = Map<String, dynamic>.from(rawJob);
    }

    if (targetJob != null) {
      targetJob['status'] = 'cancelled';
      targetJob['cancellationReason'] = reason;
      targetJob['cancelledAt'] = DateTime.now().toIso8601String();

      cancelledJobs.removeWhere((item) {
        if (item is! Map) return false;
        final jid = (item['id'] ?? item['_id'] ?? '').toString();
        return jid == id;
      });
      cancelledJobs.insert(0, targetJob);
    }

    if (Get.isRegistered<LocationService>()) {
      final loc = Get.find<LocationService>();
      if (loc.activeJobId == id) {
        if (activeJobs.isNotEmpty) {
          final first = activeJobs.first;
          final nextId = (first is Map ? (first['id'] ?? first['_id']) : null)?.toString();
          loc.setActiveJobId(nextId);
        } else {
          loc.setActiveJobId(null);
        }
      }
    }
  }

  Future<void> _invalidatePipeline() async {
    try {
      await Get.find<RefetchService>().invalidateJobPipeline();
    } catch (_) {
      await fetchJobs();
    }
  }

  Future<bool> cancelJob(String id, {String reason = 'Helper cancelled'}) async {
    try {
      final jobService = Get.find<JobService>();
      await jobService.cancelJob(id, reason);
      // Immediately reflect cancellation in memory (0ms UI latency)
      _moveJobToCancelledLocally(id, reason: reason);
      AppFeedback.success('job_cancelled_success'.tr, title: 'status_cancelled'.tr);
      // Sync with server in background
      _invalidatePipeline().catchError((_) {});
      return true;
    } catch (e) {
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> confirmCashReceived(String id) async {
    try {
      final jobService = Get.find<JobService>();
      await jobService.cashReceived(id);
      // Update local lists immediately so open detail pages re-render.
      patchJobLocally(id, {
        'paymentStatus': 'paid',
        'status': 'completed',
      });
      AppFeedback.success('ui_cash_payment_confirmed'.tr, title: 'ui_cash_received'.tr);
      // Full pipeline refresh in background — do not block UI.
      _invalidatePipeline().catchError((_) {});
      return true;
    } catch (e) {
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  /// Merge fields into the first matching local job map (by id).
  void patchJobLocally(String id, Map<String, dynamic> fields) {
    if (id.isEmpty || fields.isEmpty) return;
    for (final list in [activeJobs, completedJobs, cancelledJobs]) {
      for (var i = 0; i < list.length; i++) {
        final job = list[i];
        if (job is! Map) continue;
        final map = Map<String, dynamic>.from(job);
        final jid = (map['id'] ?? map['_id'] ?? '').toString();
        if (jid != id) continue;
        map.addAll(fields);
        list[i] = map;
        return;
      }
    }
  }

  /// Latest local copy of a job from any tab list.
  Map<String, dynamic>? findJobById(String id) {
    if (id.isEmpty) return null;
    for (final list in [activeJobs, completedJobs, cancelledJobs]) {
      for (final job in list) {
        if (job is! Map) continue;
        final map = Map<String, dynamic>.from(job);
        final jid = (map['id'] ?? map['_id'] ?? '').toString();
        if (jid == id) return map;
      }
    }
    return null;
  }
}
