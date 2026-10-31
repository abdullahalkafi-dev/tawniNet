import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/modules/common/views/legal_view.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/localization/locale_service.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelperProfileTabView extends GetView {
  const HelperProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(context),
            const SizedBox(height: 16),
            _buildAvailabilityTile(context),
            const SizedBox(height: 20),
            _buildProfileOption(context, Icons.person_outline, 'profile_edit'.tr, onTap: () => Get.toNamed(Routes.helperPublicProfile)),
            _buildProfileOption(context, Icons.account_balance_wallet_outlined, 'helper_earning'.tr, onTap: () => Get.toNamed(Routes.helperEarning)),
            _buildProfileOption(context, Icons.star_outline, 'my_reviews_title'.tr, onTap: () => Get.toNamed(Routes.myReviews)),
            _buildProfileOption(context, Icons.shopping_bag_outlined, 'helper_buy_connects'.tr, onTap: () => Get.toNamed(Routes.helperConnects)),
            _buildProfileOption(
              context,
              Icons.brightness_6_outlined,
              'ui_theme_mode'.tr,
              trailingText: Get.find<ThemeService>().themeModeName,
              onTap: () => _showThemeModeBottomSheet(context),
            ),
            Obx(
              () => _buildProfileOption(
                context,
                Icons.language,
                'profile_language'.tr,
                trailingText: Get.find<LocaleService>().currentLanguageName,
                onTap: () => _showLanguageBottomSheet(context),
              ),
            ),
            _buildProfileOption(context, Icons.notifications_none, 'profile_notification'.tr, onTap: () => Get.toNamed(Routes.helperNotifications)),
            _buildProfileOption(context, Icons.tune, 'profile_notification_settings'.tr, onTap: () => Get.toNamed(Routes.notificationSettings)),
            _buildProfileOption(context, Icons.key_outlined, 'profile_change_password'.tr, onTap: () => Get.toNamed(Routes.changePassword)),
            _buildProfileOption(context, Icons.lock_outline, 'profile_privacy'.tr, onTap: () => _showPrivacyPolicy(context)),
            _buildProfileOption(context, Icons.description_outlined, 'profile_terms'.tr, onTap: () => Get.to(() => const LegalView(kind: 'terms'))),
            _buildProfileOption(context, Icons.help_outline, 'profile_about'.tr, onTap: () => _showAboutUs(context)),
            _buildProfileOption(context, Icons.headset_mic_outlined, 'profile_help'.tr, onTap: () => Get.toNamed(Routes.helpCenter)),
            _buildProfileOption(context, Icons.delete_forever_outlined, 'profile_delete_account'.tr, isLogout: true, onTap: () => Get.toNamed(Routes.deleteAccount)),
            _buildProfileOption(context, Icons.logout, 'profile_logout'.tr, isLogout: true, onTap: () => _showLogoutDialog(context)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Obx(() {
      final user = Get.find<AuthService>().currentUser.value;
      final name = user?.name ?? 'ui_user'.tr;
      final email = user?.email ?? '';
      final avatar = user?.avatar;

      return Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(Routes.helperPublicProfile),
              child: Stack(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.cardColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: avatar != null && avatar.isNotEmpty
                          ? AppNetworkImage(url: avatar, fit: BoxFit.cover)
                          : _buildFallbackAvatar(context),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 5,
                    end: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5AB9A7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(name, style: AppStyles.h1Of(context).copyWith(fontSize: 24)),
            if (email.isNotEmpty)
              Text(
                email,
                style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
              ),
          ],
        ),
      );
    });
  }

  /// Helper on/off duty switch. Saved on the server; the switch only moves once
  /// the server confirmed, so the UI never shows a state the server doesn't have.
  Widget _buildAvailabilityTile(BuildContext context) {
    final saving = false.obs;
    return Obx(() {
      final available = Get.find<AuthService>().currentUser.value?.isAvailable ?? true;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              available ? Icons.check_circle_outline : Icons.pause_circle_outline,
              color: available ? AppColors.primary : context.textHintColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('helper_available_title'.tr, style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    available ? 'helper_available_on'.tr : 'helper_available_off'.tr,
                    style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Switch(
              value: available,
              onChanged: saving.value
                  ? null
                  : (v) async {
                      saving.value = true;
                      try {
                        await Get.find<AuthService>().setAvailability(v);
                      } catch (e) {
                        AppFeedback.error(AppSnackbar.extractErrorMessage(e));
                      } finally {
                        saving.value = false;
                      }
                    },
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      color: context.inputFillLight,
      padding: const EdgeInsets.all(32),
      child: SvgPicture.asset(
        'assets/svgs/profile_icon.svg',
        colorFilter: ColorFilter.mode(context.textHintColor, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    String? trailingText,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderSubtle),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isLogout ? Colors.redAccent : context.textPrimaryColor),
        title: Text(
          title,
          style: AppStyles.bodyLargeOf(context).copyWith(
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.redAccent : context.textPrimaryColor,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Text(
                trailingText,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.textHintColor),
          ],
        ),
      ),
    );
  }

  void _showThemeModeBottomSheet(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ui_select_theme_mode'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeOptionTile(
              context,
              title: 'ui_system_default'.tr,
              subtitle: 'ui_follow_your_device_system_setting'.tr,
              mode: ThemeMode.system,
              currentMode: themeService.themeMode.value,
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Get.back();
              },
            ),
            _buildThemeOptionTile(
              context,
              title: 'ui_light_mode'.tr,
              subtitle: 'ui_clean_white_background_and_dark_text'.tr,
              mode: ThemeMode.light,
              currentMode: themeService.themeMode.value,
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Get.back();
              },
            ),
            _buildThemeOptionTile(
              context,
              title: 'ui_dark_mode'.tr,
              subtitle: 'ui_deep_charcoal_background_and_light_text'.tr,
              mode: ThemeMode.dark,
              currentMode: themeService.themeMode.value,
              onTap: () {
                themeService.setThemeMode(ThemeMode.dark);
                Get.back();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : context.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: AppStyles.bodyLargeOf(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : context.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppStyles.bodyMedium.copyWith(
            fontSize: 12,
            color: context.textSecondaryColor,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : Icon(Icons.circle_outlined, color: context.textHintColor),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    final localeService = Get.find<LocaleService>();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'profile_language'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              // Read the observable so the tiles rebuild on change.
              localeService.currentLocale.value;
              return Column(
                children: [
                  for (final language in LocaleService.languages)
                    _buildLanguageOptionTile(
                      context,
                      title: language.nativeName,
                      subtitle: language.subtitle,
                      flag: language.flag,
                      isSelected: localeService.isSelected(language),
                      onTap: () {
                        localeService.setLocale(language.locale);
                        Get.back();
                      },
                    ),
                ],
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : context.borderSubtle,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          title,
          style: AppStyles.bodyLargeOf(context).copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primary : context.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppStyles.bodyMedium.copyWith(
            fontSize: 12,
            color: context.textSecondaryColor,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : Icon(Icons.circle_outlined, color: context.textHintColor),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
            ),
            const SizedBox(height: 16),
            Text('profile_logout_account'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'profile_logout_confirm'.tr,
              style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('btn_cancel'.tr, style: AppStyles.buttonText.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      final authService = Get.find<AuthService>();
                      await authService.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('profile_logout'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Get.toNamed(Routes.privacyPolicy);
  }

  void _showAboutUs(BuildContext context) {
    Get.toNamed(Routes.aboutUs);
  }
}
