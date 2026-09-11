import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:get/get.dart';

class HelperJobsController extends GetxController {
  final activeJobs = <dynamic>[].obs;
  final completedJobs = <dynamic>[].obs;
  final cancelledJobs = <dynamic>[].obs;
  final isLoading = false.obs;

  String? _pendingOpenJobId;

  @override
  void onInit() {
    super.onInit();
    try {
      Get.find<RefetchService>().register(
        RefetchKeys.helperJobs,
        () => fetchJobs(),
      );
    } catch (_) {}
    fetchJobs();
  }

  @override
  void onClose() {
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
      _openPendingJobDetails();
    } catch (e) {
      if (!isClosed &&
          (userInitiated ||
              (activeJobs.isEmpty &&
                  completedJobs.isEmpty &&
                  cancelledJobs.isEmpty))) {
        AppFeedback.error(
          e.toString().replaceAll('Exception: ', '').isEmpty
              ? 'Could not load jobs. Pull down to retry.'
              : e.toString().replaceAll('Exception: ', ''),
          title: 'My Job',
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
      AppFeedback.success('Job has been cancelled', title: 'Cancelled');
      await _invalidatePipeline();
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
      AppFeedback.success('Cash payment confirmed', title: 'Cash received');
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
