import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'dart:async';
import 'package:awnneaapp/app/services/job_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/widgets/app_dialogs.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/job_status_badge.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/utils/job_display.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart' show AppColors;
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:awnneaapp/app/core/widgets/job_status_timeline.dart';
import 'package:awnneaapp/app/modules/messages/views/widgets/image_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../../../data/models/booking_model.dart';
import 'live_tracking_view.dart';

class BookingDetailsView extends StatefulWidget {
  const BookingDetailsView({super.key});

  @override
  State<BookingDetailsView> createState() => _BookingDetailsViewState();
}

class _BookingDetailsViewState extends State<BookingDetailsView> {
  BookingController get controller => Get.find<BookingController>();

  Booking? _booking;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _jobEventsSub;

  @override
  void initState() {
    super.initState();
    _resolveBooking();
    // The helper moves the job along (on the way, arrived, finished…): follow it live.
    try {
      _jobEventsSub = Get.find<SocketService>().onJobUpdated.listen((event) {
        final id = _booking?.id;
        if (id != null && event['jobId']?.toString() == id) _refresh(id);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _jobEventsSub?.cancel();
    super.dispose();
  }

  /// Reload this job quietly (the screen keeps what it shows meanwhile).
  Future<void> _refresh(String id) async {
    try {
      final data = await Get.find<JobService>().getJobById(id);
      if (mounted) setState(() => _booking = Booking.fromJson(data));
    } catch (_) {}
  }

  void _resolveBooking() {
    final args = Get.arguments;
    if (args is Booking) {
      _booking = args;
      // The list may be a few seconds old: fetch the latest state in the background.
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(args.id));
      return;
    }
    String? jobId;
    if (args is String && args.isNotEmpty) {
      jobId = args;
    } else if (args is Map) {
      if (args['booking'] is Booking) {
        _booking = args['booking'] as Booking;
        return;
      }
      jobId = args['jobId']?.toString() ?? args['id']?.toString();
    }
    jobId ??= Get.parameters['id'];
    if (jobId != null && jobId.isNotEmpty && args is Map && args['booking'] is Booking) {
      return;
    }

    if (jobId != null && jobId.isNotEmpty) {
      _fetchBooking(jobId);
    }
  }

  Future<void> _fetchBooking(String id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final jobService = Get.find<JobService>();
      final data = await jobService.getJobById(id);
      if (mounted) {
        setState(() {
          _booking = Booking.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = AppSnackbar.extractErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'booking_my_bookings'.tr,
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: const SingleChildScrollView(child: DetailSkeleton()),
      );
    }

    final booking = _booking;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'booking_my_bookings'.tr,
            style: AppStyles.h2Of(context).copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage ?? 'booking_not_found'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resolveBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(
                    'booking_retry'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'booking_my_bookings'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerCard(context, booking),
            if (booking.helperSaysFinished) _buildConfirmBanner(context, booking),
            if (booking.disputeOpen) _buildDisputeBanner(context),
            if (booking.status == BookingStatus.onTheWay && booking.canTrack)
              _buildLiveTrackingHeroBanner(context, booking),
            const SizedBox(height: 24),
            _buildJobDetailRow(
              context,
              'label_job_type'.tr,
              booking.jobType.isEmpty ? 'ui_not_provided'.tr : booking.jobType,
            ),
            _buildJobDetailRow(
              context,
              'label_booking_date'.tr,
              booking.date.isEmpty ? 'ui_not_provided'.tr : booking.date,
            ),
            _buildJobDetailRow(
              context,
              'label_preferred_time'.tr,
              booking.time.isEmpty ? 'ui_not_provided'.tr : booking.time,
            ),
            _buildJobDetailRow(
              context,
              'label_location'.tr,
              booking.location.isEmpty ? 'ui_not_provided'.tr : booking.location,
            ),
            _buildJobDetailRow(
              context,
              'label_budget'.tr,
              booking.isHourly && booking.hours != null && booking.hourlyRate != null
                  ? '${formatMoney(booking.budget)}\n${'post_total_preview'.trParams({
                      'hours': _n(booking.hours!),
                      'rate': _n(booking.hourlyRate!),
                      'total': _n(booking.budget),
                    })}'
                  : formatMoney(booking.budget),
            ),
            _buildJobDetailRow(
              context,
              'ui_payment_method'.tr,
              booking.paymentMethod == 'cash' ? 'offer_pay_cash'.tr : 'offer_pay_online'.tr,
            ),
            const SizedBox(height: 24),
            _buildJobDescription(context, booking),
            const SizedBox(height: 24),
            _buildJobStatusTimeline(context, booking),
            const SizedBox(height: 40),
            if (booking.status == BookingStatus.pendingPayment) ...[
              _buildActionButton(
                'booking_pay_now'.tr,
                Colors.orange.shade700,
                () => controller.payBooking(booking),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                'booking_cancel_booking'.tr,
                Colors.white,
                () => _showCancelDialog(context, booking),
                isOutlined: true,
              ),
            ] else if (booking.status == BookingStatus.open) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.blueGrey.withValues(alpha: 0.15)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'booking_waiting_helper'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton(
                'booking_cancel_booking'.tr,
                Colors.white,
                () => _showCancelDialog(context, booking),
                isOutlined: true,
              ),
            ] else if (booking.isUnderway) ...[
              if (booking.canTrack) ...[
                _buildActionButton(
                  'booking_track_helper'.tr,
                  AppColors.primary,
                  () => _openTracking(booking),
                  icon: const Icon(Icons.near_me_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 16),
              ],
              // Confirming completes the job and releases the payment: only once the
              // helper is on site or says it is finished.
              if (booking.status == BookingStatus.arrived || booking.helperSaysFinished) ...[
                _buildActionButton(
                  'booking_complete_service'.tr,
                  const Color(0xFF0D9488),
                  () => _confirmComplete(booking),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 16),
              ],
              if (!booking.needsSupportToCancel)
                _buildActionButton(
                  'booking_cancel_booking'.tr,
                  Colors.white,
                  () => _showCancelDialog(context, booking),
                  isOutlined: true,
                )
              else if (!booking.disputeOpen)
                _buildActionButton(
                  'job_report_problem'.tr,
                  Colors.white,
                  () => _reportProblem(booking),
                  isOutlined: true,
                ),
              if (!booking.needsSupportToCancel && !booking.disputeOpen) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => _reportProblem(booking),
                    child: Text('job_report_problem'.tr),
                  ),
                ),
              ],
            ] else if (booking.status == BookingStatus.completed) ...[
              if (booking.hasReviewFromOther && booking.reviewFromOther != null)
                _buildReviewCard(
                  context,
                  title: 'booking_helper_review'.tr,
                  review: booking.reviewFromOther!,
                ),
              if (booking.hasReviewFromOther &&
                  booking.reviewFromOther != null &&
                  !(booking.hasMyReview && booking.myReview != null))
                const SizedBox(height: 16),
              if (booking.hasMyReview && booking.myReview != null)
                _buildReviewCard(
                  context,
                  title: 'booking_your_review'.tr,
                  review: booking.myReview!,
                )
              else
                _buildActionButton(
                  'btn_review'.tr,
                  AppColors.primary,
                  () => _showReviewDialog(context, booking),
                ),
            ],
            const SizedBox(height: 20),
            Center(
              child: Text(
                'booking_cancel_warning'.tr,
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 10,
                  color: context.textHintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AppAvatar(url: booking.workerImage, name: booking.workerName, size: 70),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.workerName,
                  style: AppStyles.h2Of(context).copyWith(fontSize: 18),
                ),
                Text(
                  booking.category,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    JobStatusBadge(
                      status: booking.status,
                      waitingConfirmation: booking.helperSaysFinished,
                    ),
                    _buildChatButton(booking),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _n(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  void _openTracking(Booking booking) {
    Get.to(
      () => const LiveTrackingView(),
      arguments: {
        'jobId': booking.id,
        'jobTitle': booking.title,
        'address': booking.location,
        'latitude': booking.latitude,
        'longitude': booking.longitude,
        'workerUserId': booking.workerUserId,
        'workerName': booking.workerName,
        'workerImage': booking.workerImage,
        'category': booking.category,
      },
    );
  }

  /// Completing releases the payment: always ask first.
  Future<void> _confirmComplete(Booking booking) async {
    final ok = await AppDialogs.confirm(
      title: 'job_confirm_complete_title'.tr,
      message: booking.paymentMethod == 'cash'
          ? 'job_confirm_complete_body_cash'.tr
          : 'job_confirm_complete_body_online'.tr,
      confirmLabel: 'booking_complete_service'.tr,
    );
    if (!ok) return;
    final done = await controller.completeBooking(booking.id);
    if (done && mounted) await _refresh(booking.id);
  }

  Future<void> _reportProblem(Booking booking) async {
    final text = await AppDialogs.askReason(
      title: 'job_report_problem'.tr,
      hint: 'job_report_problem_hint'.tr,
      minLength: 10,
    );
    if (text == null) return;
    final done = await controller.reportProblem(booking.id, text);
    if (done && mounted) await _refresh(booking.id);
  }

  /// "The helper says the work is finished — please confirm."
  Widget _buildConfirmBanner(BuildContext context, Booking booking) {
    final deadline = booking.autoCompleteAt;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.task_alt, color: Colors.deepPurple, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deadline == null
                  ? 'job_helper_finished_msg'.tr
                  : 'job_helper_finished_deadline'.trParams({
                      'when': AppDateTime.formatDateTimeRange(
                        date: deadline.toIso8601String(),
                        startTime: '${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}',
                      ),
                    }),
              style: AppStyles.bodyMedium.copyWith(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'job_dispute_open_msg'.tr,
              style: AppStyles.bodyMedium.copyWith(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton(Booking booking) {
    final canChat = booking.workerUserId.isNotEmpty;
    return GestureDetector(
      onTap: canChat ? () => controller.onChatWithWorker(booking) : null,
      child: Opacity(
        opacity: canChat ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                canChat ? 'btn_chat'.tr : 'job_no_helper_yet'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetailRow(BuildContext context, String label, String value) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppStyles.bodyLargeOf(context).copyWith(color: context.textSecondaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 3,
            child: Text(
              display,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription(BuildContext context, Booking booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_job_description'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'label_tasks_required'.tr,
            style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            booking.description,
            style: AppStyles.bodyMediumOf(context).copyWith(
              color: context.textSecondaryColor,
              height: 1.5,
            ),
          ),
          if (booking.photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'label_photos'.tr,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < booking.photos.length; i++)
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => ImageViewerScreen(
                            imageUrls: booking.photos,
                            initialIndex: i,
                          ),
                        );
                      },
                      child: _buildPhotoThumb(booking.photos[i]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoThumb(String url) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 12),
      width: 70,
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
      ),
      child: AppNetworkImage(url: url, width: 70, height: 70),
    );
  }

  Widget _buildJobStatusTimeline(BuildContext context, Booking booking) {
    final steps = JobTimeline.fromStatus(
      status: booking.statusApiValue,
      submittedAt: booking.createdAt,
      helperFinishedAt: booking.helperFinishedAt?.toIso8601String(),
      completedAt: booking.completedAt,
      isAssigned: booking.workerUserId.isNotEmpty,
      escrowCredited: booking.escrowCredited,
      paymentMethod: booking.paymentMethod,
    );
    return JobStatusTimeline(steps: steps);
  }

  Widget _buildLiveTrackingHeroBanner(BuildContext context, Booking booking) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? AppColors.primary.withValues(alpha: 0.12)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ui_helper_is_on_the_way'.tr,
                  style: AppStyles.h2Of(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode ? Colors.white : const Color(0xFF15803D),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'ui_live_gps'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.workerName.isNotEmpty
                ? 'ui_track_named_helper'.trParams({'name': booking.workerName})
                : 'ui_track_your_helper'.tr,
            style: AppStyles.bodySmall.copyWith(
              color: context.textSecondaryColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _openTracking(booking),
              icon: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
              label: Text(
                'ui_track_helper_live_on_map'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
    Widget? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    final reasonController = TextEditingController();
    Get.bottomSheet(
      Builder(
        builder: (dialogContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: dialogContext.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: dialogContext.borderSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE53935),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'booking_cancel_booking'.tr,
                      style: AppStyles.h2Of(dialogContext).copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'booking_cancel_question'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: dialogContext.textSecondaryColor,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (booking.paymentMethod == 'online')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'job_cancel_refund_note'.tr,
                          style: AppStyles.bodyMedium.copyWith(
                            color: dialogContext.textHintColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    TextField(
                      controller: reasonController,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: 200,
                      style: TextStyle(color: dialogContext.textPrimaryColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'job_cancel_reason_hint'.tr,
                        hintStyle: AppStyles.bodyMedium.copyWith(
                          color: dialogContext.textHintColor,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: dialogContext.inputFillColor,
                        counterText: "",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: dialogContext.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: dialogContext.borderSecondary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'btn_cancel'.tr,
                              style: TextStyle(
                                color: dialogContext.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final reason = reasonController.text.trim();
                              if (reason.length < 3) {
                                AppFeedback.error(
                                  'ui_please_enter_a_reason_at_least_3'.tr,
                                  title: 'ui_reason_required'.tr,
                                );
                                return;
                              }
                              Get.back(); // close sheet
                              final ok = await controller.cancelBooking(
                                booking.id,
                                reason: reason,
                              );
                              if (ok && Get.context != null) {
                                Get.back(); // leave details only after success
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'booking_yes_cancel'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildReviewCard(
    BuildContext context, {
    required String title,
    required MyReview review,
  }) {
    final stars = review.rating.round().clamp(0, 5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: AppStyles.h2Of(context).copyWith(fontSize: 16),
              ),
              const Spacer(),
              const Icon(Icons.verified, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < stars ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: AppStyles.bodyMediumOf(context).copyWith(height: 1.4),
            ),
          ],
          if (review.createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              AppDateTime.formatDateDisplay(review.createdAt),
              style: AppStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: context.textHintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Booking booking) {
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (dialogContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: dialogContext.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dialogContext.borderSecondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ui_rate_helper'.tr,
                    style: AppStyles.h1Of(dialogContext).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'rate_how_was'.tr.isNotEmpty
                        ? 'rate_how_was'.tr
                        : 'ui_how_was_your_experience'.tr,
                    style: AppStyles.bodyMedium.copyWith(color: dialogContext.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dialogContext.isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dialogContext.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: dialogContext.inputFillLight,
                          child: ClipOval(
                            child: AppAvatar(
                              url: booking.workerImage,
                              name: booking.workerName,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.workerName,
                                style: AppStyles.h2Of(dialogContext).copyWith(fontSize: 16),
                              ),
                              Text(
                                booking.jobType,
                                style: AppStyles.bodySmall.copyWith(color: dialogContext.textSecondaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    maxLength: 250,
                    style: TextStyle(color: dialogContext.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'rate_share'.tr.isNotEmpty
                          ? 'rate_share'.tr
                          : 'ui_share_your_feedback'.tr,
                      hintStyle: AppStyles.bodyMedium.copyWith(color: dialogContext.textHintColor),
                      filled: true,
                      fillColor: dialogContext.inputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dialogContext.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dialogContext.borderSubtle),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: dialogContext.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'btn_cancel'.tr,
                            style: TextStyle(color: dialogContext.textSecondaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (booking.workerUserId.isEmpty) {
                                    AppFeedback.info(
                                      'ui_no_assigned_helper_found_for_this_booking'.tr,
                                    );
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                  });
                                  try {
                                    final success = await controller.submitReview(
                                      jobId: booking.id,
                                      helperId: booking.workerUserId,
                                      rating: rating.toDouble(),
                                      comment: commentController.text.trim(),
                                    );
                                    if (success) {
                                      // Close sheet first — never leave spinner stuck.
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                    } else if (dialogContext.mounted) {
                                      setModalState(() {
                                        isSubmitting = false;
                                      });
                                    }
                                  } catch (_) {
                                    if (dialogContext.mounted) {
                                      setModalState(() {
                                        isSubmitting = false;
                                      });
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'rate_submit'.tr,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }
}

