import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_currency.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            style: AppStyles.h1Of(context).copyWith(
              fontSize: 24,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.textHintColor,
            labelStyle: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: 'booking_active'.tr),
              Tab(text: 'booking_unpaid'.tr),
              Tab(text: 'booking_completed'.tr),
              Tab(text: 'booking_cancelled'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingList(context, controller.activeBookings),
            _buildBookingList(context, controller.unpaidBookings),
            _buildBookingList(context, controller.completedBookings),
            _buildBookingList(context, controller.cancelledBookings),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(BuildContext context, RxList<Booking> bookings) {
    return Obx(() {
      final isLoading = controller.isLoading.value && bookings.isEmpty;

      return RefreshIndicator(
        onRefresh: () => controller.fetchBookings(),
        child: isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : bookings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      Center(child: Text('booking_no_bookings'.tr)),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            color: context.textHintColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: bookings.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildBookingCard(context, bookings[index]);
                    },
                  ),
      );
    });
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    final canChat = booking.workerUserId.isNotEmpty &&
        booking.status == BookingStatus.inProgress;
    final isUnpaid = booking.status == BookingStatus.pendingPayment;
    final isOpen = booking.status == BookingStatus.open;

    return GestureDetector(
      onTap: () {
        if (booking.status == BookingStatus.cancelled) {
          Get.toNamed(Routes.cancelDetails, arguments: booking);
        } else {
          Get.toNamed(Routes.bookingDetails, arguments: booking);
        }
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    ApiConstants.resolveImageUrl(booking.workerImage) ??
                        booking.workerImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 48,
                        height: 48,
                        color: context.inputFillLight,
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset(
                          'assets/svgs/profile_icon.svg',
                          colorFilter: ColorFilter.mode(
                            context.textHintColor,
                            BlendMode.srcIn,
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
                _buildStatusBadge(booking.status),
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
                    booking.time.isEmpty ? 'Flexible' : booking.time,
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
                    booking.location,
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
                    onPressed: () {
                      if (booking.status == BookingStatus.cancelled) {
                        Get.toNamed(Routes.cancelDetails, arguments: booking);
                      } else {
                        Get.toNamed(Routes.bookingDetails, arguments: booking);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'View details',
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
                      onPressed: isUnpaid || isOpen
                          ? () {
                              Get.toNamed(Routes.bookingDetails, arguments: booking);
                            }
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
                            ? 'Pay / Retry'
                            : isOpen
                                ? 'Waiting'
                                : 'Chat',
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

  Widget _buildStatusBadge(BookingStatus status) {
    String text;
    Color color;

    switch (status) {
      case BookingStatus.pendingPayment:
        text = 'booking_unpaid'.tr;
        color = Colors.orange.shade700;
        break;
      case BookingStatus.open:
        text = 'Looking for helper';
        color = Colors.blueGrey;
        break;
      case BookingStatus.inProgress:
        text = 'booking_inprogress'.tr;
        color = AppColors.primary;
        break;
      case BookingStatus.completed:
        text = 'booking_completed'.tr;
        color = const Color(0xFF0F766E);
        break;
      case BookingStatus.cancelled:
        text = 'booking_cancelled'.tr;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
