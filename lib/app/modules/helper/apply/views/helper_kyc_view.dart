import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class HelperKycView extends GetView<ApplyHelperController> {
  const HelperKycView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Identity Verification',
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () => controller.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Shield Badge Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Step 2 of 2: ID Verification',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Verify Moroccan Identity',
                style: AppStyles.h2Of(context).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'To guarantee safety and trust for customers on Tarik, please complete an instant automated scan of your Moroccan National ID (CIN) or Passport.',
                style: AppStyles.bodyMediumOf(context).copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Feature benefits list
              _buildFeatureCard(
                context,
                icon: Icons.credit_card_rounded,
                title: 'Moroccan CIN or Passport',
                subtitle: 'Government-issued ID verification',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.face_retouching_natural_rounded,
                title: 'Instant Biometric Liveness',
                subtitle: 'Quick 5-second 3D facial verification',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Bank-Grade Security',
                subtitle: 'End-to-end encrypted and confidential',
              ),
              const SizedBox(height: 28),

              // Status Card
              Obx(() {
                final user = authService.currentUser.value;
                final status = user?.diditStatus ?? 'Not Started';
                final isApproved = user?.helperApplicationStatus == 'approved';

                Color statusColor = Colors.grey;
                IconData statusIcon = Icons.info_outline;

                if (isApproved) {
                  statusColor = AppColors.primary;
                  statusIcon = Icons.check_circle;
                } else if (status == 'In Progress') {
                  statusColor = Colors.orange;
                  statusIcon = Icons.hourglass_top_rounded;
                } else if (status == 'Declined' || status == 'Rejected') {
                  statusColor = Colors.redAccent;
                  statusIcon = Icons.error_outline;
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification Status',
                              style: AppStyles.bodyMedium.copyWith(
                                color: context.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isApproved ? 'Approved & Active' : status,
                              style: AppStyles.bodyLargeOf(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.isSyncingKyc.value)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),

              // Primary Action: Start Didit Scan
              Obx(() => CustomButton(
                text: controller.isStartingKyc.value
                    ? 'Opening Didit...'
                    : 'Start Moroccan ID Scan with Didit',
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: controller.isStartingKyc.value
                    ? () {}
                    : controller.launchDiditKyc,
              )),
              const SizedBox(height: 14),

              // Secondary: Check Status
              Obx(() => OutlinedButton.icon(
                onPressed: controller.isSyncingKyc.value
                    ? null
                    : () => controller.syncKycStatus(showFeedback: true),
                icon: controller.isSyncingKyc.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  controller.isSyncingKyc.value
                      ? 'Checking Verification...'
                      : 'I\'ve Completed Verification (Check Status)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppStyles.bodyMedium.copyWith(
                    color: context.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
