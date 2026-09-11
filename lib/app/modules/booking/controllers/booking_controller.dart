import 'dart:async';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
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
  final completedBookings = <Booking>[].obs;
  final cancelledBookings = <Booking>[].obs;
  final unpaidBookings = <Booking>[].obs;
  final isLoading = false.obs;

  String? _pendingOpenJobId;
  StreamSubscription? _jobAcceptedSub;

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
    _listenForJobAccepted();
  }

  @override
  void onClose() {
    try {
      Get.find<RefetchService>().unregister(RefetchKeys.activeBookings);
    } catch (_) {}
    _jobAcceptedSub?.cancel();
    super.onClose();
  }

  Future<void> _invalidatePipeline() async {
    try {
      await Get.find<RefetchService>().invalidateJobPipeline();
    } catch (_) {
      await fetchBookings();
    }
  }

  void _listenForJobAccepted() {
    try {
      final socket = Get.find<SocketService>();
      _jobAcceptedSub = socket.onJobAccepted.listen((_) {
        if (!isClosed) fetchBookings();
      });
    } catch (_) {}
    try {
      final socket = Get.find<SocketService>();
      socket.onJobCancelled.listen((_) {
        if (!isClosed) fetchBookings();
      });
      socket.onJobCompleted.listen((_) {
        if (!isClosed) fetchBookings();
      });
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
      } catch (_) {
        // Skip malformed row — don't wipe the whole list.
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
    isLoading.value = true;
    try {
      final jobService = Get.find<JobService>();
      final res = await jobService.getMyBookings();

      final active = _mapBookings(res['active']);
      final completed = _mapBookings(res['completed']);
      final cancelled = _mapBookings(res['cancelled']);
      final unpaid = _mapBookings(res['unpaid']);

      // Older backends may still lump pending_payment into active
      if (unpaid.isEmpty) {
        final stillUnpaid = active
            .where((b) => b.status == BookingStatus.pendingPayment)
            .toList();
        if (stillUnpaid.isNotEmpty) {
          active.removeWhere((b) => b.status == BookingStatus.pendingPayment);
          unpaid.addAll(stillUnpaid);
        }
      }

      activeBookings.assignAll(active);
      completedBookings.assignAll(completed);
      cancelledBookings.assignAll(cancelled);
      unpaidBookings.assignAll(unpaid);

      _openPendingJobDetails();
    } catch (e) {
      if (!isClosed &&
          (userInitiated ||
              (activeBookings.isEmpty && unpaidBookings.isEmpty))) {
        AppFeedback.error(
          e.toString().replaceAll('Exception: ', '').isEmpty
              ? 'Could not load bookings. Pull down to retry.'
              : e.toString().replaceAll('Exception: ', ''),
          title: 'Bookings',
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

    Booking? match;
    for (final b in [...activeBookings, ...completedBookings, ...cancelledBookings]) {
      if (b.id == id) {
        match = b;
        break;
      }
    }
    if (match != null) {
      // Defer so the list screen is mounted first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (Get.currentRoute == Routes.booking || Get.currentRoute == '/') {
          Get.toNamed(Routes.bookingDetails, arguments: match);
        }
      });
    }
  }

  Future<void> onChatWithWorker(Booking booking) async {
    if (booking.workerUserId.isEmpty) {
      AppFeedback.error(
        'No helper assigned yet. Chat opens after a helper accepts the job.',
        title: 'Chat unavailable',
      );
      return;
    }

    try {
      final messagesController = Get.find<MessagesController>();
      final conversation =
          await messagesController.startConversation(booking.workerUserId);
      if (conversation != null && !Get.isSnackbarOpen) {
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
      } else if (conversation == null && !Get.isSnackbarOpen) {
        AppFeedback.error('Could not open chat. Try again.', title: 'Chat');
      }
    } catch (_) {
      AppFeedback.error('Could not open chat. Try again.', title: 'Chat');
    }
  }

  Future<bool> cancelBooking(String id, {String reason = 'Client cancelled'}) async {
    try {
      if (reason.trim().length < 3) {
        reason = 'Client requested cancellation';
      }
      final jobService = Get.find<JobService>();
      await jobService.cancelJob(id, reason.trim());
      AppFeedback.success('Your booking has been cancelled', title: 'Booking Cancelled');
      await _invalidatePipeline();
      return true;
    } catch (e) {
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> completeBooking(String id) async {
    try {
      final jobService = Get.find<JobService>();
      await jobService.completeJob(id);
      AppFeedback.success('Booking marked as completed', title: 'Completed');
      await _invalidatePipeline();
    } catch (e) {
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
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
        AppFeedback.error('Could not start payment. Try again.');
        return;
      }
      final paid = await Get.toNamed(
        Routes.checkout,
        arguments: {
          'orderId': booking.id,
          'orderType': 'job',
          'amount': booking.budget,
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
      AppFeedback.error(e.toString().replaceAll('Exception: ', ''));
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
      AppFeedback.success(
        'Thank you! Your feedback has been recorded.',
        title: 'Review Submitted',
      );
      // Refresh lists in background — never block the review modal
      _invalidatePipeline().catchError((_) {});
      return true;
    } catch (e) {
      AppFeedback.error(
        e.toString().replaceAll('Exception: ', ''),
        title: 'Could not submit review',
      );
      return false;
    }
  }
}

