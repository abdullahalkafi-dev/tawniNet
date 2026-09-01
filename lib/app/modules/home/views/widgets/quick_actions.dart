import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class QuickActions extends GetView<HomeController> {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: controller.onFindHelperTap,
            child: _buildActionCard(
              context,
              title: 'Find Helper',
              subtitle: 'Browse Services',
              icon: Icons.search,
              color: context.isDarkMode
                  ? AppColors.primary.withOpacity(0.15)
                  : const Color(0xFFE5F7F5),
              iconBgColor: AppColors.primary,
              iconColorOverride: Colors.white,
              titleColor: context.isDarkMode ? AppColors.primary : const Color(0xFF5AB9A7),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: controller.onPostJobTap,
            child: _buildActionCard(
              context,
              title: 'Post a job',
              subtitle: '',
              icon: Icons.track_changes,
              color: context.cardColor,
              iconBgColor: context.inputFillLight,
              iconColorOverride: context.textPrimaryColor,
              titleColor: context.textPrimaryColor,
              hasBorder: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconBgColor,
    required Color iconColorOverride,
    required Color titleColor,
    bool hasBorder = false,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: context.borderSubtle) : null,
        boxShadow: hasBorder
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColorOverride, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: titleColor,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
