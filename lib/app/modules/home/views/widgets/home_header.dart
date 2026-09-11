import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/notification_badge_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Obx(() {
          final user = Get.find<AuthService>().currentUser.value;
          final avatar = user?.avatar;
          return ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: avatar != null && avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context),
                  )
                : _buildAvatarPlaceholder(context),
          );
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Location',
                style: AppStyles.bodyMedium.copyWith(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Obx(() {
                final address = Get.find<AuthService>().currentUser.value?.address;
                return Text(
                  address?.isNotEmpty == true ? address! : 'No location set',
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            controller.onNotificationTap();
            if (Get.isRegistered<NotificationBadgeController>()) {
              Get.find<NotificationBadgeController>().refresh();
            }
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: context.textPrimaryColor,
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Obx(() {
                  final count = Get.isRegistered<NotificationBadgeController>()
                      ? Get.find<NotificationBadgeController>().unread.value
                      : 0;
                  // No badge when everything is read (same as helper home).
                  if (count <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.cardColor, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      color: context.inputFillLight,
      padding: const EdgeInsets.all(10),
      child: SvgPicture.asset(
        'assets/svgs/profile_icon.svg',
        colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
      ),
    );
  }
}
