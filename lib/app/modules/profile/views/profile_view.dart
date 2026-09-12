import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/localization/locale_service.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'profile_title'.tr,
          style: AppStyles.h1Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 40),
              _buildProfileOption(
                context,
                Icons.person_outline,
                'profile_edit'.tr,
                onTap: () => Get.toNamed(Routes.editProfile),
              ),
              _buildProfileOption(
                context,
                Icons.notifications_none,
                'profile_notification'.tr,
                onTap: () => Get.toNamed(Routes.notificationSettings),
              ),
              _buildProfileOption(
                context,
                Icons.brightness_6_outlined,
                'Theme Mode',
                trailingText: Get.find<ThemeService>().themeModeName,
                onTap: () => _showThemeModeBottomSheet(context),
              ),
              _buildProfileOption(
                context,
                Icons.payment,
                'profile_payment'.tr,
                onTap: () => _showPaymentBottomSheet(context),
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
              _buildProfileOption(
                context,
                Icons.lock_outline,
                'profile_privacy'.tr,
                onTap: () => _showPrivacyPolicyBottomSheet(context),
              ),
              _buildProfileOption(
                context,
                Icons.help_outline,
                'profile_about'.tr,
                onTap: () => _showAboutUsBottomSheet(context),
              ),
              _buildProfileOption(
                context,
                Icons.headset_mic_outlined,
                'profile_help'.tr,
                onTap: () => _showHelpSupportBottomSheet(context),
              ),
              _buildProfileOption(
                context,
                Icons.logout,
                'profile_logout'.tr,
                isLogout: true,
                onTap: () => _showLogoutDialog(context),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Obx(() {
      final user = Get.find<AuthService>().currentUser.value;
      final name = user?.name ?? 'User';
      final email = user?.email ?? '';
      final avatar = user?.avatar;

      return Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Get.toNamed(Routes.editProfile),
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
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: avatar != null && avatar.isNotEmpty
                          ? Image.network(
                              avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildFallbackAvatar(context);
                              },
                            )
                          : _buildFallbackAvatar(context),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF5AB9A7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
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

  Widget _buildFallbackAvatar(BuildContext context) {
    return Container(
      color: context.inputFillLight,
      padding: const EdgeInsets.all(32),
      child: SvgPicture.asset(
        'assets/svgs/profile_icon.svg',
        colorFilter: ColorFilter.mode(
          context.textHintColor,
          BlendMode.srcIn,
        ),
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
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : context.textPrimaryColor,
        ),
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
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.textHintColor,
            ),
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
              'Select Theme Mode',
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            _buildThemeOptionTile(
              context,
              title: 'System Default',
              subtitle: 'Follow your device system setting',
              mode: ThemeMode.system,
              currentMode: themeService.themeMode.value,
              onTap: () {
                themeService.setThemeMode(ThemeMode.system);
                Get.back();
              },
            ),
            _buildThemeOptionTile(
              context,
              title: 'Light Mode',
              subtitle: 'Clean white background and dark text',
              mode: ThemeMode.light,
              currentMode: themeService.themeMode.value,
              onTap: () {
                themeService.setThemeMode(ThemeMode.light);
                Get.back();
              },
            ),
            _buildThemeOptionTile(
              context,
              title: 'Dark Mode',
              subtitle: 'Deep charcoal background and light text',
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
              final isAr = localeService.isArabic;
              return Column(
                children: [
                  _buildLanguageOptionTile(
                    context,
                    title: 'English',
                    subtitle: 'English (US)',
                    flag: '🇺🇸',
                    isSelected: !isAr,
                    onTap: () {
                      localeService.setLocale(const Locale('en', 'US'));
                      Get.back();
                    },
                  ),
                  _buildLanguageOptionTile(
                    context,
                    title: 'العربية',
                    subtitle: 'Moroccan Arabic (الدارجة)',
                    flag: '🇲🇦',
                    isSelected: isAr,
                    onTap: () {
                      localeService.setLocale(const Locale('ar', 'MA'));
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

  void _showPaymentBottomSheet(BuildContext context) {
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
              'profile_payment_methods'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentCardTile(
              context,
              'Visa ending in 4242',
              'Expires 12/28',
              Icons.credit_card,
              true,
            ),
            _buildPaymentCardTile(
              context,
              'Mastercard ending in 9876',
              'Expires 05/27',
              Icons.credit_card,
              false,
            ),
            _buildPaymentCardTile(context, 'Apple Pay', 'Connected', Icons.apple, false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  'profile_add_card'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5AB9A7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCardTile(
    BuildContext context,
    String name,
    String details,
    IconData icon,
    bool isDefault,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.textPrimaryColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.bodyLargeOf(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.isDarkMode ? AppColors.primary.withOpacity(0.15) : const Color(0xFFE5F7F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'profile_default'.tr,
                style: TextStyle(
                  color: context.isDarkMode ? AppColors.primary : const Color(0xFF5AB9A7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyBottomSheet(BuildContext context) {
    String content = '';
    bool isLoading = true;

    Future<void> load() async {
      try {
        final api = Get.find<ApiClient>();
        final res = await api.get(ApiConstants.legal);
        if (res.success && res.data is Map) {
          final data = Map<String, dynamic>.from(res.data as Map);
          content = (data['privacyPolicy'] ?? '').toString();
        }
      } catch (_) {
        content = '';
      }
      isLoading = false;
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          if (isLoading) {
            load().then((_) {
              if (sheetContext.mounted) {
                setSheetState(() {});
              }
            });
          }
          return Container(
            height: context.height * 0.7,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
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
                  'profile_privacy'.tr,
                  style: AppStyles.h2Of(context).copyWith(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Text(
                            content.isEmpty
                                ? 'Privacy policy will appear here once published by the admin.'
                                : content,
                            style: AppStyles.bodyMediumOf(context).copyWith(
                              color: context.textSecondaryColor,
                              height: 1.5,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5AB9A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'profile_accept_close'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showAboutUsBottomSheet(BuildContext context) {
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
            const Icon(
              Icons.home_repair_service,
              size: 50,
              color: Color(0xFF5AB9A7),
            ),
            const SizedBox(height: 12),
            Text(
              'profile_about_title'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'profile_version'.tr,
              style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'profile_about_desc'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMediumOf(context).copyWith(
                  color: context.textSecondaryColor,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'profile_copyright'.tr,
              style: TextStyle(color: context.textHintColor, fontSize: 11),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportBottomSheet(BuildContext context) {
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
              'profile_help'.tr,
              style: AppStyles.h2Of(context).copyWith(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 20),
            _buildSupportTile(
              context,
              'profile_contact_chat'.tr,
              'profile_chat_reply'.tr,
              Icons.chat_bubble_outline,
              () {
                Get.back();
                Get.toNamed(Routes.supportTicketList);
              },
            ),
            _buildSupportTile(
              context,
              'profile_email_support'.tr,
              'support@awnnea.com',
              Icons.email_outlined,
              () {
                print('Email support clicked');
              },
            ),
            _buildSupportTile(
              context,
              'profile_call_hotline'.tr,
              '+1 (800) 555-0199',
              Icons.phone_outlined,
              () {
                print('Phone support clicked');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF5AB9A7)),
        title: Text(
          title,
          style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.textSecondaryColor, fontSize: 12),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: context.textHintColor,
        ),
      ),
    );
  }
}
