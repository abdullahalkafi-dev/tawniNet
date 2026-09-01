import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../core/values/app_assets.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_styles.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppAssets.appLogo,
              height: 150,
            ),
            const SizedBox(height: 10),
            Text(
              'splash_brand'.tr,
              style: AppStyles.h1.copyWith(
                fontSize: 40,
                color: context.textPrimaryColor,
              ),
            ),
            Text(
              'splash_help_text'.tr,
              style: AppStyles.bodyMedium.copyWith(
                fontSize: 18,
                color: context.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 100),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 5,
            ),
            const SizedBox(height: 10),
            Text(
              'splash_loading'.tr,
              style: AppStyles.bodyMediumOf(context),
            ),
          ],
        ),
      ),
    );
  }
}
