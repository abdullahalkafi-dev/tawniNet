import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/review_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:get/get.dart';
import '../../../data/models/booking_model.dart';

class BookingController extends GetxController {
  final activeBookings = <Booking>[].obs;
  final awaitingBookings = <Booking>[].obs;
  final completedBookings = <Booking>[].obs;
  final cancelledBookings = <Booking>[].obs;
  final unpaidBookings = <Booking>[].obs;

  /// True while the very first load is running (drives the skeleton).
  final isLoading = false.obs;
  final hasLoadedOnce = false.obs;

  /// The last load failed and there is nothing to show yet (drives the retry state).
  final loadFailed = false.obs;

  /// "Load more" state of the two finished tabs.
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
    final args = Get.arguments;
    if (args is Map && args['jobId'] != null) {
      _pendingOpenJobId = args['jobId'].toString();
    } else if (args is String && args.isNotEmpty) {
      _pendingOpenJobId = args;
    }
    try {
      Get.find<RefetchService>().register(
        RefetchKeys.activeBookings,
        () => fetchBookings(),
      );
    } catch (_) {}
    fetchBookings();
    _listenForJobEvents();
  }

  @override
  void onClose() {
    try {
      Get.find<RefetchService>().unregister(RefetchKeys.activeBookings);
    } catch (_) {}
    for (final s in _subs) {
      s.cancel();
    }
    _refreshDebounce?.cancel();
    super.onClose();
  }

  Future<void> _invalidatePipeline() async {
    try {
      await Get.find<RefetchService>().invalidateJobPipeline();
    } catch (_) {
      await fetchBookings();
    }
  }

  /// Any change on one of my jobs (accepted, on the way, arrived, finished,
  /// cancelled…) refreshes the lists. Bursts of events become one request.
  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) fetchBookings();
    });
  }

  void _listenForJobEvents() {
    try {
      final socket = Get.find<SocketService>();
      _subs.addAll([
        socket.onJobAccepted.listen((_) => _scheduleRefresh()),
        socket.onJobUpdated.listen((_) => _scheduleRefresh()),
        socket.onJobCancelled.listen((_) => _scheduleRefresh()),
        socket.onJobCompleted.listen((_) => _scheduleRefresh()),
        socket.onPaymentVerified.listen((_) => _scheduleRefresh()),
      ]);
    } catch (_) {}
  }

  List<Booking> _mapBookings(dynamic raw) {
    if (raw is! List) return [];
    final out = <Booking>[];
    for (final item in raw) {
      try {
        if (item is Map) {
          out.add(Booking.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (e) {
        // Skip malformed row — don't wipe the whole list.
        if (kDebugMode) debugPrint('[Bookings] skipped a row: $e');
      }
    }
    return out;
  }

  Future<void>? _fetchInFlight;

  /// Safe for pull-to-refresh: joins an in-flight fetch instead of stacking.
  Future<void> fetchBookings({bool userInitiated = false}) {
    final existing = _fetchInFlight;
    if (existing != null) return existing;
    final future = _fetchBookingsImpl(userInitiated: userInitiated);
    _fetchInFlight = future;
    return future.whenComplete(() {
      if (identical(_fetchInFlight, future)) {
        _fetchInFlight = null;
      }
    });
  }

  Future<void> _fetchBookingsImpl({bool userInitiated = false}) async {
    // Only the very first load shows skeletons; later refreshes update in place.
    if (!hasLoadedOnce.value) isLoading.value = true;
    try {
      final res = await Get.find<JobService>().getMyBookings();

      final active = _mapBookings(res['active']);
      final awaiting = _mapBookings(res['awaiting']);
      final completed = _mapBookings(res['completed']);
      final cancelled = _mapBookings(res['cancelled']);
      final unpaid = _mapBookings(res['unpaid']);

      activeBookings.assignAll(active);
      // Awaiting = still looking for a helper + payment not finished.
      awaitingBookings.assignAll([...awaiting, ...unpaid]);
      completedBookings.assignAll(completed);
      cancelledBookings.assignAll(cancelled);
      unpaidBookings.assignAll(unpaid);

      final counts = res['counts'] is Map ? res['counts'] as Map : const {};
      completedHasMore.value = completed.length < ((counts['completed'] as num?)?.toInt() ?? 0);
      cancelledHasMore.value = cancelled.length < ((counts['cancelled'] as num?)?.toInt() ?? 0);
      _completedPage = 1;
      _cancelledPage = 1;

      hasLoadedOnce.value = true;
      loadFailed.value = false;
      _openPendingJobDetails();
    } catch (e) {
      final nothingToShow = activeBookings.isEmpty &&
          awaitingBookings.isEmpty &&
          completedBookings.isEmpty &&
          cancelledBookings.isEmpty;
      if (!isClosed) {
        if (nothingToShow && !hasLoadedOnce.value) loadFailed.value = true;
        // A failed silent refresh keeps what is on screen; only an explicit pull explains why.
        if (userInitiated) {
          AppFeedback.error(AppSnackbar.extractErrorMessage(e), title: 'ui_bookings'.tr);
        }
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  /// Next page of the Completed / Cancelled tab.
  Future<void> loadMore(BookingStatus tab) async {
    if (isLoadingMore.value) return;
    final isCompleted = tab == BookingStatus.completed;
    if (!(isCompleted ? completedHasMore.value : cancelledHasMore.value)) return;
    isLoadingMore.value = true;
    try {
      final page = (isCompleted ? _completedPage : _cancelledPage) + 1;
      final res = await Get.find<JobService>()
          .getMyBookingsPage(isCompleted ? 'completed' : 'cancelled', page);
      final docs = _mapBookings(res['docs']);
      final target = isCompleted ? completedBookings : cancelledBookings;
      final known = target.map((b) => b.id).toSet();
      target.addAll(docs.where((b) => !known.contains(b.id)));
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

  void setPendingOpenJobId(String jobId) {
    _pendingOpenJobId = jobId;
    if (!isLoading.value) {
      _openPendingJobDetails();
    }
  }

  void _openPendingJobDetails() async {
    final id = _pendingOpenJobId;
    if (id == null || id.isEmpty) return;
    _pendingOpenJobId = null;

    Booking? match;
    for (final b in [
      ...activeBookings,
      ...awaitingBookings,
      ...unpaidBookings,
      ...completedBookings,
      ...cancelledBookings,
    ]) {
      if (b.id == id) {
        match = b;
        break;
      }
    }
    // Pass the id: the details screen loads the fresh job itself.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (Get.currentRoute == Routes.booking || Get.currentRoute == '/' || Get.currentRoute == Routes.home) {
        Get.toNamed(Routes.bookingDetails, arguments: match ?? id);
      }
    });
  }

  Future<void> onChatWithWorker(Booking booking) async {
    if (booking.workerUserId.isEmpty) {
      AppFeedback.error(
        'ui_no_helper_assigned_yet_chat_opens_after'.tr,
        title: 'ui_chat_unavailable'.tr,
      );
      return;
    }

    final messagesController = Get.find<MessagesController>();
    final conversation = await messagesController.startConversation(booking.workerUserId);
    if (conversation != null) {
      final other = conversation.otherParticipant;
      Get.toNamed(
        Routes.chatDetail,
        arguments: ChatSummary(
          id: conversation.id,
          name: other?.name ?? booking.workerName,
          image: other?.avatar ?? booking.workerImage,
          otherUserId: booking.workerUserId,
        ),
      );
    }
  }

  Future<bool> cancelBooking(String id, {required String reason, String? code}) async {
    try {
      await Get.find<JobService>().cancelJob(id, reason.trim(), code: code);
      AppFeedback.success('ui_your_booking_has_been_cancelled'.tr, title: 'ui_booking_cancelled'.tr);
      await _invalidatePipeline();
      return true;
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  /// The client confirms the work was done (this releases the payment).
  Future<bool> completeBooking(String id) async {
    try {
      await Get.find<JobService>().completeJob(id);
      AppFeedback.success('ui_booking_marked_as_completed'.tr, title: 'status_completed'.tr);
      await _invalidatePipeline();
      return true;
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> reportProblem(String id, String message) async {
    try {
      await Get.find<JobService>().reportProblem(id, message);
      AppFeedback.success('job_problem_reported'.tr);
      await _invalidatePipeline();
      return true;
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
      return false;
    }
  }

  /// Re-open checkout for an unpaid job.
  Future<void> payBooking(Booking booking) async {
    try {
      final jobService = Get.find<JobService>();
      final res = await jobService.retryJobCheckout(booking.id);
      final checkoutUrl = res['checkoutUrl']?.toString() ?? '';
      final sessId = res['sessionId']?.toString() ?? '';
      if (checkoutUrl.isEmpty) {
        AppFeedback.error('ui_could_not_start_payment_try_again'.tr);
        return;
      }
      final paid = await Get.toNamed(
        Routes.checkout,
        arguments: {
          'orderId': booking.id,
          'orderType': 'job',
          'amount': (res['amount'] as num?)?.toDouble() ?? booking.budget,
          'currency': 'MAD',
          'title': booking.jobType,
          'sessionId': sessId,
          'metadata': {
            'userId': Get.find<AuthService>().currentUser.value?.id,
            'jobId': booking.id,
          },
        },
      );
      if (paid == true) {
        await _invalidatePipeline();
      }
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    }
  }

  Future<bool> submitReview({
    required String jobId,
    required String helperId,
    required num rating,
    String? comment,
  }) async {
    try {
      final reviewService = Get.find<ReviewService>();
      await reviewService.submitReview(
        jobId: jobId,
        revieweeId: helperId,
        rating: rating.toDouble(),
        comment: comment,
      );
    } catch (e) {
      AppFeedback.error(
        AppSnackbar.extractErrorMessage(e),
        title: 'ui_could_not_submit_review'.tr,
      );
      return false;
    }

    // Close UI first (caller pops modal), then toast + refresh in background.
    scheduleMicrotask(() {
      try {
        AppFeedback.success(
          'ui_thank_you_your_feedback_has_been_recorded'.tr,
          title: 'ui_review_submitted'.tr,
        );
      } catch (_) {}
      _invalidatePipeline().catchError((_) {});
    });
    return true;
  }
}
