import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/widgets/app_pull_to_refresh.dart';
import 'package:awnneaapp/app/core/widgets/job_status_badge.dart';
import 'package:awnneaapp/app/core/widgets/skeleton.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/booking_controller.dart';
import '../../../data/models/booking_model.dart';

class BookingView extends GetView<BookingController> {
  const BookingView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'booking_my_bookings'.tr,
            style: AppStyles.h1Of(context).copyWith(fontSize: 24),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.textHintColor,
            labelStyle: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'booking_awaiting'.tr),
              Tab(text: 'booking_active'.tr),
              Tab(text: 'booking_completed'.tr),
              Tab(text: 'booking_cancelled'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingList(context, controller.awaitingBookings),
            _buildBookingList(context, controller.activeBookings),
            _buildBookingList(context, controller.completedBookings,
                loadMoreTab: BookingStatus.completed),
            _buildBookingList(context, controller.cancelledBookings,
                loadMoreTab: BookingStatus.cancelled),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(
    BuildContext context,
    RxList<Booking> bookings, {
    BookingStatus? loadMoreTab,
  }) {
    // RefreshIndicator must stay OUTSIDE Obx — otherwise isLoading flips
    // rebuild the indicator and cancel the pull gesture.
    return AppPullToRefresh(
      onRefresh: () => controller.fetchBookings(userInitiated: true),
      child: Obx(() {
        // First load: cards that look like the real ones.
        if (!controller.hasLoadedOnce.value && !controller.loadFailed.value && bookings.isEmpty) {
          return SkeletonList(
            count: 4,
            spacing: 16,
            padding: const EdgeInsets.all(20),
            itemBuilder: (_, __) => const JobCardSkeleton(),
          );
        }

        if (controller.loadFailed.value && bookings.isEmpty) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              Icon(Icons.cloud_off_outlined, size: 56, color: context.textHintColor),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'ui_could_not_load_bookings_pull_down_to'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => controller.fetchBookings(userInitiated: true),
                  icon: const Icon(Icons.refresh),
                  label: Text('booking_retry'.tr),
                ),
              ),
            ],
          );
        }

        if (bookings.isEmpty) {
          return ListView(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
              Icon(Icons.event_note_outlined, size: 56, color: context.textHintColor),
              const SizedBox(height: 12),
              Center(child: Text('booking_no_bookings'.tr)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'ui_pull_down_to_refresh'.tr,
                  style: TextStyle(color: context.textHintColor, fontSize: 12),
                ),
              ),
            ],
          );
        }

        final hasMore = loadMoreTab == BookingStatus.completed
            ? controller.completedHasMore.value
            : loadMoreTab == BookingStatus.cancelled
                ? controller.cancelledHasMore.value
                : false;

        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (loadMoreTab != null &&
                hasMore &&
                n.metrics.pixels > n.metrics.maxScrollExtent - 300) {
              controller.loadMore(loadMoreTab);
            }
            return false;
          },
          child: ListView.separated(
            primary: false,
            physics: AppAlwaysScrollPhysics,
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length + (hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index >= bookings.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _buildBookingCard(context, bookings[index]);
            },
          ),
        );
      }),
    );
  }

  void _open(Booking booking) {
    if (booking.status == BookingStatus.cancelled) {
      Get.toNamed(Routes.cancelDetails, arguments: booking);
    } else {
      Get.toNamed(Routes.bookingDetails, arguments: booking);
    }
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final canChat = booking.workerUserId.isNotEmpty && booking.isUnderway;
    final isUnpaid = booking.status == BookingStatus.pendingPayment;
    final isOpen = booking.status == BookingStatus.open;

    return GestureDetector(
      onTap: () => _open(booking),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(url: booking.workerImage, name: booking.workerName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.workerName,
                        style: AppStyles.h2Of(context).copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.category,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                JobStatusBadge(
                  status: booking.status,
                  waitingConfirmation: booking.helperSaysFinished,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: context.textHintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.date.isEmpty ? '—' : booking.date,
                    style: AppStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
                Icon(Icons.access_time, size: 14, color: context.textHintColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    booking.time.isEmpty ? 'ui_flexible'.tr : booking.time,
                    style: AppStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: context.textHintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    booking.location.isEmpty ? 'ui_not_provided'.tr : booking.location,
                    style: AppStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      color: context.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatMoney(booking.budget),
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _open(booking),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'connects_view_details'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (isUnpaid || canChat || isOpen) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isUnpaid
                          ? () => controller.payBooking(booking)
                          : isOpen
                              ? () => Get.toNamed(Routes.bookingDetails, arguments: booking)
                              : () => controller.onChatWithWorker(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isUnpaid
                            ? Colors.orange.shade700
                            : isOpen
                                ? Colors.blueGrey
                                : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        isUnpaid
                            ? 'ui_pay_retry'.tr
                            : isOpen
                                ? 'ui_waiting'.tr
                                : 'btn_chat'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
