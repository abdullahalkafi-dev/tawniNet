import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelperProfileTabView extends GetView {
  const HelperProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildProfileHeader(),
            const SizedBox(height: 30),
            _buildProfileOption(Icons.person_outline, 'Edit Profile', onTap: () => Get.toNamed(Routes.helperPublicProfile)),
            _buildProfileOption(Icons.account_balance_wallet_outlined, 'Earning', onTap: () => Get.toNamed(Routes.helperEarning)),
            _buildProfileOption(Icons.shopping_bag_outlined, 'Buy Connects', onTap: () => Get.toNamed(Routes.helperConnects)),
            _buildProfileOption(Icons.notifications_none, 'Notification', onTap: () => Get.toNamed(Routes.helperNotifications)),
            _buildProfileOption(Icons.lock_outline, 'Privacy Policy', onTap: () => _showPrivacyPolicy(context)),
            _buildProfileOption(Icons.help_outline, 'About US', onTap: () => _showAboutUs(context)),
            _buildProfileOption(Icons.headset_mic_outlined, 'Help & Support', onTap: () => Get.toNamed(Routes.helpCenter)),
            _buildProfileOption(Icons.logout, 'Logout', isLogout: true, onTap: () => _showLogoutDialog(context)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
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
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.all(32),
                        child: SvgPicture.asset(
                          'assets/svgs/profile_icon.svg',
                          colorFilter: const ColorFilter.mode(Color(0xFF9CA3AF), BlendMode.srcIn),
                        ),
                      );
                    },
                  ),
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
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          ),
          const SizedBox(height: 20),
          Text('Sarah Johnson', style: AppStyles.h1.copyWith(fontSize: 24)),
          Text(
            'Sarahjohnson@gmail.com',
            style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {required VoidCallback onTap, bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isLogout ? Colors.redAccent : Colors.black87),
        title: Text(
          title,
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.redAccent : Colors.black87,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Logout Account', style: AppStyles.h2.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Are you sure to logout from this account?',
              style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
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
                    child: Text('Cancel', style: AppStyles.buttonText.copyWith(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.offAllNamed(Routes.roleSelection);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
