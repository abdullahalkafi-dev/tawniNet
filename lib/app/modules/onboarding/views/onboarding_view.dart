import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../../../core/localization/locale_service.dart';
import '../../../core/values/app_assets.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_styles.dart';
import '../../../core/widgets/theme_toggle_icon_button.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                children: [
                  _buildPage(
                    context,
                    image: AppAssets.onboarding1,
                    title: 'onboarding_welcome'.tr,
                    highlightText: 'onboarding_brand'.tr,
                    description: 'onboarding_find_desc'.tr,
                  ),
                  _buildPage(
                    context,
                    image: AppAssets.onboarding2,
                    title: 'onboarding_hire'.tr,
                    highlightText: 'onboarding_helpers'.tr,
                    description: 'onboarding_helpers_desc'.tr,
                  ),
                  _buildPage(
                    context,
                    image: AppAssets.onboarding3,
                    title: 'onboarding_offer'.tr,
                    highlightText: 'onboarding_skills'.tr,
                    description: 'onboarding_skills_desc'.tr,
                  ),
                ],
              ),
            ),
            _buildIndicators(context),
            const SizedBox(height: 40),
            _buildBottomButtons(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final localeService = Get.find<LocaleService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language Switcher Pill
          GestureDetector(
            onTap: controller.toggleLanguage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Obx(() {
                final isArabic = localeService.currentLocale.value.languageCode == 'ar';
                return Row(
                  children: [
                    Icon(Icons.language, size: 18, color: isArabic ? Colors.green : Colors.red),
                    const SizedBox(width: 6),
                    Text(
                      isArabic ? 'lang_arabic'.tr : 'lang_english'.tr,
                      style: AppStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                );
              }),
            ),
          ),
          // Dark/Light Mode Switcher
          const ThemeToggleIconButton(),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
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
              style: AppStyles.h2.copyWith(fontSize: 28, color: context.textPrimaryColor),
              children: [
                TextSpan(text: title),
                TextSpan(
                  text: highlightText,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators(BuildContext context) {
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
                  : (context.isDarkMode ? AppColors.darkBorder : Colors.grey[300]),
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
              child: Text('onboarding_get_started'.tr),
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
                'onboarding_skip'.tr,
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.next,
              child: Text(
                'onboarding_next'.tr,
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
