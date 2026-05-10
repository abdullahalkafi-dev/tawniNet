import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/values/app_styles.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Profile & Settings', style: AppStyles.h1.copyWith(fontSize: 18, color: Colors.grey)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 40),
            _buildProfileOption(Icons.person_outline, 'Edit Profile'),
            _buildProfileOption(Icons.notifications_none, 'Notification'),
            _buildProfileOption(Icons.payment, 'Payment'),
            _buildProfileOption(Icons.lock_outline, 'Privacy Policy'),
            _buildProfileOption(Icons.help_outline, 'About US'),
            _buildProfileOption(Icons.headset_mic_outlined, 'Help & Support'),
            _buildProfileOption(Icons.logout, 'Logout', isLogout: true),
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
          Stack(
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
                  ],
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C6AC4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Sarah Johnson', style: AppStyles.h1.copyWith(fontSize: 24)),
          Text('Sarahjohnson@gmail.com', style: AppStyles.bodyMedium.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () {
          if (isLogout) {
            Get.offAllNamed('/login');
          } else if (title == 'Edit Profile') {
            Get.toNamed(Routes.editProfile);
          } else if (title == 'Notification') {
            Get.toNamed(Routes.notificationSettings);
          }
        },
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
}
