import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class ApplicationPendingView extends GetView<ApplyHelperController> {
  const ApplicationPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final user = authService.currentUser.value;
          final isAppeal = user?.helperApplicationStatus == 'pending_appeal' ||
              user?.appealStatus == 'pending';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: (isAppeal ? Colors.orange : AppColors.primary).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAppeal ? Icons.hourglass_top_rounded : Icons.access_time,
                    size: 50,
                    color: isAppeal ? Colors.orange : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  isAppeal ? 'Appeal Under Review' : 'app_pending_title'.tr,
                  style: AppStyles.h2Of(context).copyWith(
                    fontSize: 26,
                    color: isAppeal ? Colors.orange : AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isAppeal
                      ? 'Your review appeal has been submitted to the compliance team. We will notify you once a decision is finalized.'
                      : 'app_pending_desc'.tr,
                  style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 15, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Text(
                    isAppeal
                        ? 'Appeals are usually reviewed within 12-24 hours.'
                        : 'app_pending_time'.tr,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: isAppeal ? Colors.orange : AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAppeal ? 'Verification Appeal' : 'app_pending_documents'.tr,
                              style: AppStyles.bodyLargeOf(context).copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'app_pending_under_review'.tr,
                              style: AppStyles.bodyMedium.copyWith(
                                color: isAppeal ? Colors.orange : AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isAppeal ? Colors.orange : Colors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                OutlinedButton.icon(
                  onPressed: () async {
                    await authService.getMe();
                    final updatedUser = authService.currentUser.value;
                    if (updatedUser?.helperApplicationStatus == 'approved') {
                      Get.offAllNamed(Routes.helperHome);
                    } else if (updatedUser?.helperApplicationStatus == 'rejected') {
                      Get.offAllNamed(Routes.applicationRejected);
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Check Status'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'app_pending_logout'.tr,
                  onPressed: controller.logout,
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        }),
      ),
    );
  }
}
