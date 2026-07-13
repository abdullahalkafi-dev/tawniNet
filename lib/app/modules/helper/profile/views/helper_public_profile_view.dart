import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperPublicProfileView extends StatefulWidget {
  const HelperPublicProfileView({super.key});

  @override
  State<HelperPublicProfileView> createState() => _HelperPublicProfileViewState();
}

class _HelperPublicProfileViewState extends State<HelperPublicProfileView> {
  bool isAvailable = true;
  bool isAboutExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'public_profile'.tr,
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final user = Get.find<AuthService>().currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 20),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildAboutSection(user),
              const SizedBox(height: 24),
              _buildPhotosSection(user),
              const SizedBox(height: 24),
              _buildInfoSection(user),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    final avatar = user.avatar;
    final name = user.name ?? 'Helper';
    final serviceName = user.serviceType != null
        ? (user.serviceType is String
            ? user.serviceType
            : user.serviceType['name'] ?? '')
        : '';

    return Center(
      child: Column(
        children: [
          ClipOval(
            child: avatar != null && avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
          const SizedBox(height: 12),
          Text(name, style: AppStyles.h1.copyWith(fontSize: 22)),
          if (serviceName.isNotEmpty)
            Text(
              serviceName,
              style: AppStyles.bodyMedium.copyWith(fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.toNamed(Routes.helperEditProfile),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text('public_edit_info'.tr, style: AppStyles.buttonText.copyWith(color: AppColors.primary, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => isAvailable = !isAvailable),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? AppColors.primary : Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              isAvailable ? 'public_available'.tr : 'public_unavailable'.tr,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(dynamic user) {
    final bio = user.bio ?? '';
    if (bio.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_about_me'.tr, style: AppStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'No bio added yet.',
            style: AppStyles.bodyMedium.copyWith(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('label_about_me'.tr, style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => isAboutExpanded = !isAboutExpanded),
          child: RichText(
            text: TextSpan(
              text: isAboutExpanded ? bio : (bio.length > 120 ? '${bio.substring(0, 120)}...' : bio),
              style: AppStyles.bodyMedium.copyWith(height: 1.5),
              children: [
                if (bio.length > 120)
                  TextSpan(
                    text: isAboutExpanded ? 'btn_read_less'.tr : 'btn_read_more'.tr,
                    style: AppStyles.bodyMedium.copyWith(
                      height: 1.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection(dynamic user) {
    final profilePhotos = user.profilePhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('label_photos'.tr, style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        if (profilePhotos == null || profilePhotos.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No photos added yet', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: profilePhotos.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  profilePhotos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: AppStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        _buildInfoRow(Icons.location_on_outlined, 'Location', user.address ?? 'Not set'),
        _buildInfoRow(Icons.work_outline, 'Experience', '${user.experience ?? 0} years'),
        _buildInfoRow(Icons.attach_money, 'Price', '${user.pricePerHour ?? 0}/hour'),
        _buildInfoRow(Icons.language, 'Language', user.language ?? 'Not set'),
        _buildInfoRow(Icons.my_location, 'Service Radius', '${user.serviceRadius ?? 0} km'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: Colors.grey)),
              Text(value, style: AppStyles.bodyLarge.copyWith(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
