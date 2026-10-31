import 'dart:async';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:get/get.dart';

class HelperJobsController extends GetxController {
  final activeJobs = <dynamic>[].obs;
  final completedJobs = <dynamic>[].obs;
  final cancelledJobs = <dynamic>[].obs;

  /// True while the very first load runs (drives the skeleton).
  final isLoading = false.obs;
  final hasLoadedOnce = false.obs;

  /// The last load failed and there is nothing to show (drives the retry state).
  final loadFailed = false.obs;

  final completedHasMore = false.obs;
  final cancelledHasMore = false.obs;
  final isLoadingMore = false.obs;
  int _completedPage = 1;
  int _cancelledPage = 1;

  String? _pendingOpenJobId;
  final _subs = <StreamSubscription>[];
  Timer? _refreshDebounce;

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
    for (final s in _subs) {
      s.cancel();
    }
    _refreshDebounce?.cancel();
    try {
      Get.find<RefetchService>().unregister(RefetchKeys.helperJobs);
    } catch (_) {}
    super.onClose();
  }

  /// Queue a job id to auto-open after the next successful fetch (push deep-link).
  void setPendingOpenJobId(String? jobId) {
    if (jobId == null || jobId.isEmpty) return;
    _pendingOpenJobId = jobId;
    if (hasLoadedOnce.value) {
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
    if (!hasLoadedOnce.value) isLoading.value = true;
    try {
      final res = await Get.find<JobService>().getMyAssignedJobs();

      activeJobs.assignAll((res['active'] as List?) ?? []);
      completedJobs.assignAll((res['completed'] as List?) ?? []);
      cancelledJobs.assignAll((res['cancelled'] as List?) ?? []);

      final counts = res['counts'] is Map ? res['counts'] as Map : const {};
      completedHasMore.value = completedJobs.length < ((counts['completed'] as num?)?.toInt() ?? 0);
      cancelledHasMore.value = cancelledJobs.length < ((counts['cancelled'] as num?)?.toInt() ?? 0);
      _completedPage = 1;
      _cancelledPage = 1;

      hasLoadedOnce.value = true;
      loadFailed.value = false;
      _syncTracking();
      _openPendingJobDetails();
    } catch (e) {
      // The lists are NOT cleared on a failed refresh: the helper keeps seeing what he had.
      if (!isClosed) {
        final nothingToShow =
            activeJobs.isEmpty && completedJobs.isEmpty && cancelledJobs.isEmpty;
        if (nothingToShow && !hasLoadedOnce.value) loadFailed.value = true;
        if (userInitiated) {
          AppFeedback.error(AppSnackbar.extractErrorMessage(e), title: 'helper_my_job'.tr);
        }
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  Future<void> loadMore(String tab) async {
    if (isLoadingMore.value) return;
    final isCompleted = tab == 'completed';
    if (!(isCompleted ? completedHasMore.value : cancelledHasMore.value)) return;
    isLoadingMore.value = true;
    try {
      final page = (isCompleted ? _completedPage : _cancelledPage) + 1;
      final res = await Get.find<JobService>().getMyAssignedJobsPage(tab, page);
      final docs = (res['docs'] as List?) ?? [];
      final target = isCompleted ? completedJobs : cancelledJobs;
      final known = target.whereType<Map>().map((m) => (m['_id'] ?? m['id']).toString()).toSet();
      target.addAll(docs.where((d) => d is Map && !known.contains((d['_id'] ?? d['id']).toString())));
      final more = (res['totalPages'] as num? ?? 0) > page;
      if (isCompleted) {
        _completedPage = page;
        completedHasMore.value = more;
      } else {
        _cancelledPage = page;
        cancelledHasMore.value = more;
      }
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Share the position with the client exactly while a job is "on the way".
  void _syncTracking() {
    if (!Get.isRegistered<LocationService>()) return;
    final loc = Get.find<LocationService>();
    String? travelling;
    for (final job in activeJobs) {
      if (job is Map && (job['status'] ?? '').toString() == 'on_the_way') {
        travelling = (job['id'] ?? job['_id'])?.toString();
        break;
      }
    }
    if (travelling != null && travelling.isNotEmpty) {
      loc.startJobTracking(travelling);
    } else {
      loc.stopJobTracking();
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

  /// Any change on one of my jobs refreshes the lists. Bursts become one request.
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) _invalidatePipeline().catchError((_) {});
    });
  }

  void _setupSocketListeners() {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();

    _subs.addAll([
      socket.onJobUpdated.listen((_) => _scheduleRefresh()),
      socket.onJobCompleted.listen((_) => _scheduleRefresh()),
      socket.onJobCancelled.listen((data) {
        final jid = (data['id'] ?? data['_id'] ?? data['jobId'])?.toString();
        if (jid != null && jid.isNotEmpty) {
          final title = (data['title'] ?? '').toString();
          final wasActive = activeJobs.any((item) {
            if (item is! Map) return false;
            return (item['id'] ?? item['_id'] ?? '').toString() == jid;
          });
          if (wasActive) {
            AppFeedback.info(
              title.isEmpty
                  ? 'job_cancelled_by_client_generic'.tr
                  : 'job_cancelled_by_client'.trParams({'title': title}),
              title: 'cancel_job_cancelled'.tr,
            );
          }
        }
        _scheduleRefresh();
      }),
      // A job I was offered was taken by someone else: refresh the open list.
      socket.onJobUnavailable.listen((_) {
        try {
          Get.find<RefetchService>().invalidate(RefetchKeys.nearbyJobs);
        } catch (_) {}
      }),
    ]);
  }

  Future<void> _invalidatePipeline() async {
    try {
      await Get.find<RefetchService>().invalidateJobPipeline();
    } catch (_) {
      await fetchJobs();
    }
  }

  // ─── Actions on an accepted job ───────────────────────

  Future<bool> _step(Future<dynamic> Function() call, String successKey, {Map<String, dynamic>? patch, required String id}) async {
    try {
      await call();
      if (patch != null) patchJobLocally(id, patch);
      AppFeedback.success(successKey.tr);
      _invalidatePipeline().catchError((_) {});
      return true;
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      // The job may have moved on (cancelled by the client…): show the real state.
      unawaited(fetchJobs());
      return false;
    }
  }

  /// "I'm on my way" — starts sharing the position with the client.
  Future<bool> startTravelling(String id) async {
    final ok = await _step(
      () => Get.find<JobService>().markOnTheWay(id),
      'job_step_on_the_way_done',
      id: id,
      patch: {'status': 'on_the_way', 'onTheWayAt': DateTime.now().toIso8601String()},
    );
    if (ok && Get.isRegistered<LocationService>()) {
      Get.find<LocationService>().startJobTracking(id);
    }
    return ok;
  }

  /// "I've arrived" — stops the live tracking.
  Future<bool> markArrived(String id) async {
    final ok = await _step(
      () => Get.find<JobService>().markArrived(id),
      'job_step_arrived_done',
      id: id,
      patch: {'status': 'arrived', 'arrivedAt': DateTime.now().toIso8601String()},
    );
    if (ok && Get.isRegistered<LocationService>()) {
      Get.find<LocationService>().stopJobTracking();
    }
    return ok;
  }

  /// "Work finished" — the client now confirms (or it completes by itself).
  Future<bool> markFinished(String id) async {
    final ok = await _step(
      () => Get.find<JobService>().markFinished(id),
      'job_step_finished_done',
      id: id,
      patch: {'helperFinishedAt': DateTime.now().toIso8601String()},
    );
    if (ok && Get.isRegistered<LocationService>()) {
      Get.find<LocationService>().stopJobTracking();
    }
    return ok;
  }

  Future<bool> reportProblem(String id, String message) async {
    try {
      await Get.find<JobService>().reportProblem(id, message);
      patchJobLocally(id, {'disputeOpen': true});
      AppFeedback.success('job_problem_reported'.tr);
      _invalidatePipeline().catchError((_) {});
      return true;
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  void _moveJobToCancelledLocally(String id, {String reason = 'Cancelled'}) {
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
    _syncTracking();
  }

  Future<bool> cancelJob(String id, {required String reason, String? code}) async {
    try {
      await Get.find<JobService>().cancelJob(id, reason, code: code);
      // Immediately reflect cancellation in memory (0ms UI latency)
      _moveJobToCancelledLocally(id, reason: reason);
      AppFeedback.success('job_cancelled_success'.tr, title: 'status_cancelled'.tr);
      // Sync with server in background
      _invalidatePipeline().catchError((_) {});
      return true;
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> confirmCashReceived(String id) async {
    try {
      await Get.find<JobService>().cashReceived(id);
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
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
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
