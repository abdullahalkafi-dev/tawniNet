import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
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
        ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Image.network(
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: const Color(0xFFF3F4F6),
                padding: const EdgeInsets.all(10),
                child: SvgPicture.asset(
                  'assets/svgs/profile_icon.svg',
                  colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Column(
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
            Text(
              'Manchester',
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: controller.onNotificationTap,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1F2937),
                ),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 10,
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
