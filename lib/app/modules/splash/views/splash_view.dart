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
              '3awniNet',
              style: AppStyles.h1.copyWith(
                fontSize: 40,
                color: const Color(0xFF2D1408), // Darker brown from image
              ),
            ),
            Text(
              'Help is in your hands.',
              style: AppStyles.bodyMedium.copyWith(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'المساعدة بين يديك',
              style: AppStyles.bodyMedium.copyWith(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 100),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 5,
            ),
            const SizedBox(height: 10),
            Text(
              'Loading...',
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
