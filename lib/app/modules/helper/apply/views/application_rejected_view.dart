import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class ApplicationRejectedView extends GetView<ApplyHelperController> {
  const ApplicationRejectedView({super.key});

  void _showAppealDialog(BuildContext context) {
    final appealController = TextEditingController();
    final isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit Review Appeal',
                style: AppStyles.h2Of(context).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Explain why your verification should be reconsidered or provide additional context.',
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: appealController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your appeal explanation here...',
                  hintStyle: TextStyle(color: context.textHintColor, fontSize: 14),
                  filled: true,
                  fillColor: context.inputFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.borderSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('Cancel', style: TextStyle(color: context.textSecondaryColor)),
                  ),
                  const SizedBox(width: 8),
                  Obx(
                    () => ElevatedButton(
                      onPressed: isSubmitting.value
                          ? null
                          : () async {
                              final message = appealController.text.trim();
                              if (message.length < 5) {
                                AppSnackbar.showError('Appeal message must be at least 5 characters');
                                return;
                              }
                              isSubmitting.value = true;
                              try {
                                final authService = Get.find<AuthService>();
                                await authService.submitAppeal(message);
                                Get.back();
                                AppSnackbar.showSuccess(
                                  'Your appeal has been submitted and is pending admin review.',
                                  title: 'Appeal Submitted',
                                );
                              } catch (e) {
                                AppSnackbar.showError(e);
                              } finally {
                                isSubmitting.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isSubmitting.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Appeal', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final user = authService.currentUser.value;
          final rejectionReason = user?.rejectionReason ??
              user?.diditDecisionReason ??
              'Application did not satisfy document or biometric requirements.';
          final appealStatus = user?.appealStatus ?? 'none';
          final appealCount = user?.appealCount ?? 0;
          final isAppealPending = appealStatus == 'pending';
          final canAppeal = appealCount < 3 && !isAppealPending && appealStatus != 'max_exceeded';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isAppealPending
                        ? Colors.orange.withOpacity(0.12)
                        : AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAppealPending ? Icons.hourglass_top_rounded : Icons.close,
                    size: 46,
                    color: isAppealPending ? Colors.orange : AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isAppealPending ? 'Appeal Under Review' : 'app_status_title'.tr,
                  style: AppStyles.h1Of(context).copyWith(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  isAppealPending
                      ? 'Your appeal is currently pending review by our compliance team.'
                      : 'app_status_not_approved'.tr,
                  style: AppStyles.bodyLarge.copyWith(
                    color: isAppealPending ? Colors.orange : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isAppealPending
                      ? 'We are reviewing your appeal details. You will receive an update once a decision is made.'
                      : 'app_status_rejected_desc'.tr,
                  style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? AppColors.error.withOpacity(0.12)
                        : AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'app_status_reason'.tr,
                        style: AppStyles.bodyLarge.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rejectionReason,
                        style: AppStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (canAppeal) ...[
                  CustomButton(
                    text: 'Submit Appeal (${3 - appealCount} attempts left)',
                    onPressed: () => _showAppealDialog(context),
                  ),
                  const SizedBox(height: 16),
                ],
                CustomButton(
                  text: 'app_status_re_apply'.tr,
                  onPressed: controller.updateAndReapply,
                  isOutlined: canAppeal,
                ),
                const SizedBox(height: 16),
                Text(
                  'app_status_re_apply_desc'.tr,
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    fontSize: 13,
                    color: context.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }),
      ),
    );
  }
}
