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
              title: 'Find Helper',
              subtitle: 'Browse Services',
              icon: Icons.search,
              color: const Color(0xFFE0F7F6),
              iconColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: controller.onPostJobTap,
            child: _buildActionCard(
              title: 'Post a job',
              subtitle: '',
              icon: Icons.post_add,
              color: Colors.white,
              iconColor: AppColors.secondary,
              hasBorder: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    bool hasBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: AppStyles.bodyMedium.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
