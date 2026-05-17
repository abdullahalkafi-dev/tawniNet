import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Profile & Settings',
          style: AppStyles.h1.copyWith(fontSize: 18, color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 40),
            _buildProfileOption(context, Icons.person_outline, 'Edit Profile', onTap: () => Get.toNamed(Routes.editProfile)),
            _buildProfileOption(context, Icons.notifications_none, 'Notification', onTap: () => Get.toNamed(Routes.notificationSettings)),
            _buildProfileOption(context, Icons.payment, 'Payment', onTap: () => _showPaymentBottomSheet(context)),
            _buildProfileOption(context, Icons.lock_outline, 'Privacy Policy', onTap: () => _showPrivacyPolicyBottomSheet(context)),
            _buildProfileOption(context, Icons.help_outline, 'About US', onTap: () => _showAboutUsBottomSheet(context)),
            _buildProfileOption(context, Icons.headset_mic_outlined, 'Help & Support', onTap: () => _showHelpSupportBottomSheet(context)),
            _buildProfileOption(context, Icons.logout, 'Logout', isLogout: true, onTap: () => Get.offAllNamed(Routes.login)),
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
            onTap: () => Get.toNamed(Routes.editProfile),
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

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : Colors.black87,
        ),
        title: Text(
          title,
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.redAccent : Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _showPaymentBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Methods',
              style: AppStyles.h2.copyWith(fontSize: 20, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 20),
            _buildPaymentCardTile('Visa ending in 4242', 'Expires 12/28', Icons.credit_card, true),
            _buildPaymentCardTile('Mastercard ending in 9876', 'Expires 05/27', Icons.credit_card, false),
            _buildPaymentCardTile('Apple Pay', 'Connected', Icons.apple_global, false),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add New Card', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5AB9A7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCardTile(String name, String details, IconData icon, bool isDefault) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1F2937), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(details, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F7F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Default', style: TextStyle(color: Color(0xFF5AB9A7), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        height: context.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Privacy Policy',
              style: AppStyles.h2.copyWith(fontSize: 20, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated: May 2026',
                      style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Information We Collect',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We collect information you provide directly to us when creating or modifying your account, requesting on-demand services, contacting support, or otherwise communicating with us. This info includes name, email, phone number, profile photo, payment method, and details of services requested.',
                      style: AppStyles.bodyMedium.copyWith(color: const Color(0xFF4B5563), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '2. How We Use the Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We use the information we collect to provide, maintain, and improve our Services, including facilitating payments, sending receipts, providing products and services you request, and enabling communications between you and helpers.',
                      style: AppStyles.bodyMedium.copyWith(color: const Color(0xFF4B5563), height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '3. Data Sharing & Security',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We do not sell your personal data. We share details with workers to facilitate service delivery. We utilize standard industry firewalls and SSL encryption to safeguard data privacy.',
                      style: AppStyles.bodyMedium.copyWith(color: const Color(0xFF4B5563), height: 1.5),
                    ),
                  ],
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Accept & Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAboutUsBottomSheet(BuildContext context) {
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
            const Icon(Icons.home_repair_service, size: 50, color: Color(0xFF5AB9A7)),
            const SizedBox(height: 12),
            Text(
              'About Awnnea',
              style: AppStyles.h2.copyWith(fontSize: 20, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0 (Build 120)',
              style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Awnnea is the #1 on-demand household helper platform. We connect verified professionals with users seeking high-quality repairs, cleaning, shifting, and shifting services. Founded on trust, reliability, and modern efficiency.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(color: const Color(0xFF4B5563), height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '© 2026 Awnnea Inc. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Help & Support',
              style: AppStyles.h2.copyWith(fontSize: 20, color: const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 20),
            _buildSupportTile('Contact via Live Chat', 'Typical reply under 5 mins', Icons.chat_bubble_outline, () {
              Get.back();
              Get.toNamed(
                Routes.chatDetail,
                arguments: ChatSummary(
                  id: 'support_agent',
                  name: 'Awnnea Support Agent',
                  image: 'https://i.pravatar.cc/150?u=support',
                  lastMessage: 'How can I assist you today?',
                  time: 'Now',
                  unreadCount: 0,
                  isOnline: true,
                ),
              );
            }),
            _buildSupportTile('Email Support', 'support@awnnea.com', Icons.email_outlined, () {
              print('Email support clicked');
            }),
            _buildSupportTile('Call Hotline', '+1 (800) 555-0199', Icons.phone_outlined, () {
              print('Phone support clicked');
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF5AB9A7)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}
