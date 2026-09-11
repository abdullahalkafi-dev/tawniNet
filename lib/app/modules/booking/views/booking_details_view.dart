import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
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

class BookingDetailsView extends GetView<BookingController> {
  const BookingDetailsView({super.key});

  static Booking? _readBookingArg() {
    final args = Get.arguments;
    if (args is Booking) return args;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final booking = _readBookingArg();
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
            child: Text(
              'Booking not found. Go back and try again.',
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
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
            const SizedBox(height: 24),
            _buildJobDetailRow(context, 'label_job_type'.tr, booking.jobType),
            _buildJobDetailRow(context, 'label_booking_date'.tr, booking.date),
            _buildJobDetailRow(context, 'label_preferred_time'.tr, booking.time),
            _buildJobDetailRow(context, 'label_location'.tr, booking.location),
            _buildJobDetailRow(context, 'label_budget'.tr, formatMoney(booking.budget)),
            const SizedBox(height: 24),
            _buildJobDescription(context, booking),
            const SizedBox(height: 24),
            _buildJobStatusTimeline(context, booking),
            const SizedBox(height: 40),
            if (booking.status == BookingStatus.pendingPayment) ...[
              _buildActionButton(
                'Pay now',
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
                      ? Colors.blueGrey.withOpacity(0.15)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Waiting for a helper to accept. Payment is already done.',
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
            ] else if (booking.status == BookingStatus.inProgress) ...[
              _buildActionButton('Complete Service', AppColors.primary, () {
                controller.completeBooking(booking.id);
                Get.back();
              }),
              const SizedBox(height: 16),
              _buildActionButton(
                'booking_cancel_booking'.tr,
                Colors.white,
                () => _showCancelDialog(context, booking),
                isOutlined: true,
              ),
            ] else if (booking.status == BookingStatus.completed) ...[
              if (booking.hasReviewFromOther && booking.reviewFromOther != null)
                _buildReviewCard(
                  context,
                  title: 'Helper review',
                  review: booking.reviewFromOther!,
                ),
              if (booking.hasReviewFromOther &&
                  booking.reviewFromOther != null &&
                  !(booking.hasMyReview && booking.myReview != null))
                const SizedBox(height: 16),
              if (booking.hasMyReview && booking.myReview != null)
                _buildReviewCard(
                  context,
                  title: 'Your review',
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final resolved =
                  ApiConstants.resolveImageUrl(booking.workerImage);
              final hasPhoto = resolved != null && resolved.isNotEmpty;
              return CircleAvatar(
                radius: 35,
                backgroundColor: context.inputFillLight,
                backgroundImage: hasPhoto ? NetworkImage(resolved) : null,
                onBackgroundImageError: hasPhoto ? (_, __) {} : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, size: 32, color: Colors.grey),
              );
            },
          ),
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
                    _buildStatusBadge(booking.status),
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

  Widget _buildStatusBadge(BookingStatus status) {
    String text;
    switch (status) {
      case BookingStatus.pendingPayment:
        text = 'booking_unpaid'.tr;
        break;
      case BookingStatus.open:
        text = 'Looking for helper';
        break;
      case BookingStatus.inProgress:
        text = 'booking_inprogress'.tr;
        break;
      case BookingStatus.completed:
        text = 'booking_completed'.tr;
        break;
      case BookingStatus.cancelled:
        text = 'booking_cancelled'.tr;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
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
                canChat ? 'btn_chat'.tr : 'No helper yet',
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
      margin: const EdgeInsets.only(right: 12),
      width: 70,
      height: 70,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.background,
      ),
      child: Image.network(
        ApiConstants.resolveImageUrl(url) ?? url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  Widget _buildJobStatusTimeline(BuildContext context, Booking booking) {
    final steps = JobTimeline.fromStatus(
      status: booking.statusApiValue,
      submittedAt: booking.createdAt,
      completedAt: booking.completedAt,
      isAssigned: booking.workerUserId.isNotEmpty,
      escrowCredited: booking.escrowCredited,
      paymentMethod: booking.paymentMethod,
    );
    return JobStatusTimeline(steps: steps);
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                        color: Colors.red.withOpacity(0.12),
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
                    const SizedBox(height: 14),
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
                                  'Please enter a reason (at least 3 characters).',
                                  title: 'Reason required',
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
                    'rate_title'.tr.isNotEmpty ? 'rate_title'.tr : 'Rate Helper',
                    style: AppStyles.h1Of(dialogContext).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'rate_how_was'.tr.isNotEmpty
                        ? 'rate_how_was'.tr
                        : 'How was your experience?',
                    style: AppStyles.bodyMedium.copyWith(color: dialogContext.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dialogContext.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dialogContext.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: dialogContext.inputFillLight,
                          backgroundImage: (() {
                            final resolved = ApiConstants.resolveImageUrl(
                              booking.workerImage,
                            );
                            if (resolved == null || resolved.isEmpty) {
                              return null;
                            }
                            return NetworkImage(resolved) as ImageProvider;
                          })(),
                          child: booking.workerImage.isEmpty
                              ? const Icon(Icons.person, color: AppColors.primary)
                              : null,
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
                          : 'Share your feedback...',
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
                                    Get.snackbar(
                                      'Notice',
                                      'No assigned helper found for this booking.',
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }
                                  setModalState(() {
                                    isSubmitting = true;
                                  });
                                  final success = await controller.submitReview(
                                    jobId: booking.id,
                                    helperId: booking.workerUserId,
                                    rating: rating.toDouble(),
                                    comment: commentController.text.trim(),
                                  );
                                  if (success) {
                                    Get.back();
                                  } else {
                                    setModalState(() {
                                      isSubmitting = false;
                                    });
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
                                  'rate_submit'.tr.isNotEmpty ? 'rate_submit'.tr : 'Submit Review',
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

