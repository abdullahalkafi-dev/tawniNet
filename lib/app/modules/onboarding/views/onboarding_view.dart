import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../../../core/values/app_assets.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_styles.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: [
                  _buildPage(
                    image: AppAssets.onboarding1,
                    title: 'Welcome to ',
                    highlightText: '3awniNet',
                    description:
                        'Find what you need — cleaning, fixing, moving — and let others help!',
                  ),
                  _buildPage(
                    image: AppAssets.onboarding2,
                    title: 'Hire Nearby ',
                    highlightText: 'skilled Helpers',
                    description: 'Verified helpers ready to assist you anytime.',
                  ),
                  _buildPage(
                    image: AppAssets.onboarding3,
                    title: 'Offer your ',
                    highlightText: 'skills and earn',
                    description:
                        'If you have a skill, 3awniNet helps you connect with clients and grow your income',
                  ),
                ],
              ),
            ),
            _buildIndicators(),
            const SizedBox(height: 40),
            _buildBottomButtons(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.language, size: 20, color: Colors.red), // Flag icon replacement
                const SizedBox(width: 8),
                Text('Eng', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String image,
    required String title,
    required String highlightText,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 300),
          const SizedBox(height: 40),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppStyles.h2.copyWith(fontSize: 28, color: Colors.black),
              children: [
                TextSpan(text: title),
                TextSpan(
                  text: highlightText,
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators() {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: controller.currentPage.value == index
                  ? AppColors.primary
                  : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Obx(() {
      final isLastPage = controller.currentPage.value == 2;
      if (isLastPage) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: controller.next,
              child: const Text('Get Started'),
            ),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: controller.skip,
              child: Text(
                'Skip',
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.next,
              child: Text(
                'Next',
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
