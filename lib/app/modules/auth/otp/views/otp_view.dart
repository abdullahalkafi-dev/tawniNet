import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/otp_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';
import '../../../../core/widgets/custom_button.dart';

import '../../../../core/widgets/theme_toggle_icon_button.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ThemeToggleIconButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF25D366),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'WhatsApp Verification',
                style: AppStyles.h1Of(context).copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the 6-digit verification code sent to\n${controller.formattedPhone}',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 15),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => _buildOtpField(index, context),
                ),
              ),
              const SizedBox(height: 24),
              // Simulation helper button for testing
              OutlinedButton.icon(
                onPressed: controller.fillTestOtp,
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Fill Test Code (123456)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => CustomButton(
                  text: 'auth_verify'.tr,
                  onPressed: controller.verifyOtp,
                  isLoading: controller.isLoading.value,
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("auth_no_code".tr + ' ', style: AppStyles.bodyMediumOf(context)),
                    GestureDetector(
                      onTap: controller.canResend.value ? controller.resendOtp : null,
                      child: Text(
                        controller.canResend.value
                            ? 'auth_resend'.tr
                            : '${'auth_resend'.tr} (${controller.resendCooldown.value}s)',
                        style: AppStyles.bodyMedium.copyWith(
                          color: controller.canResend.value
                              ? AppColors.primary
                              : context.textHintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index, BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextFormField(
        controller: controller.otpControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        decoration: InputDecoration(
          counterText: "",
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: context.inputFillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.borderSecondary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: context.borderSecondary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }
}
