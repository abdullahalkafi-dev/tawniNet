import 'package:awnneaapp/app/core/values/app_colors.dart';
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
      length: 3,
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
              Tab(text: 'booking_completed'.tr),
              Tab(text: 'booking_cancelled'.tr),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookingList(controller.activeBookings),
            _buildBookingList(controller.completedBookings),
            _buildBookingList(controller.cancelledBookings),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(RxList<Booking> bookings) {
    return Obx(() {
      if (bookings.isEmpty) {
        return Center(child: Text('booking_no_bookings'.tr));
      }
      return RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement booking refresh when API is ready
        },
        child: ListView.separated(
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
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.network(
                    booking.workerImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: context.inputFillLight,
                        padding: const EdgeInsets.all(18),
                        child: SvgPicture.asset(
                          'assets/svgs/profile_icon.svg',
                          colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.workerName,
                        style: AppStyles.h2Of(context).copyWith(
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        booking.category,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusBadge(booking.status),
                          const Spacer(),
                          _buildChatButton(booking),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Icon(Icons.keyboard_arrow_down, color: context.textHintColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    String text;
    Color color;
    
    switch (status) {
      case BookingStatus.inProgress:
        text = 'booking_inprogress'.tr;
        color = AppColors.primary.withOpacity(0.5);
        break;
      case BookingStatus.completed:
        text = 'booking_completed'.tr;
        color = AppColors.primary.withOpacity(0.5);
        break;
      case BookingStatus.cancelled:
        text = 'booking_cancelled'.tr;
        color = Colors.orange;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChatButton(Booking booking) {
    return GestureDetector(
      onTap: () => controller.onChatWithWorker(booking),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'btn_chat'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
