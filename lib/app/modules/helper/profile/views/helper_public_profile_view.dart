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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'public_profile'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        final user = Get.find<AuthService>().currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Get.find<AuthService>().getMe();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(context, user),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildAboutSection(context, user),
                const SizedBox(height: 24),
                _buildPhotosSection(context, user),
                const SizedBox(height: 24),
                _buildInfoSection(context, user),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
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
                    errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(context),
                  )
                : _buildAvatarPlaceholder(context),
          ),
          const SizedBox(height: 12),
          Text(name, style: AppStyles.h1Of(context).copyWith(fontSize: 22)),
          if (serviceName.isNotEmpty)
            Text(
              serviceName,
              style: AppStyles.bodyMedium.copyWith(fontSize: 14, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: context.inputFillLight,
      child: Icon(Icons.person, size: 40, color: context.textHintColor),
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

  Widget _buildAboutSection(BuildContext context, dynamic user) {
    final bio = user.bio ?? '';
    if (bio.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_about_me'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            'No bio added yet.',
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('label_about_me'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => isAboutExpanded = !isAboutExpanded),
          child: RichText(
            text: TextSpan(
              text: isAboutExpanded ? bio : (bio.length > 120 ? '${bio.substring(0, 120)}...' : bio),
              style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5),
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

  Widget _buildPhotosSection(BuildContext context, dynamic user) {
    final profilePhotos = user.profilePhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('label_photos'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        if (profilePhotos == null || profilePhotos.isEmpty)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.inputFillLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('No photos added yet', style: TextStyle(color: context.textHintColor)),
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: context.inputFillLight,
                    child: Icon(Icons.image, color: context.textHintColor),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        _buildInfoRow(context, Icons.location_on_outlined, 'Location', user.address ?? 'Not set'),
        _buildInfoRow(context, Icons.work_outline, 'Experience', '${user.experience ?? 0} years'),
        _buildInfoRow(context, Icons.attach_money, 'Price', '${user.pricePerHour ?? 0}/hour'),
        _buildInfoRow(context, Icons.language, 'Language', user.language ?? 'Not set'),
        _buildInfoRow(context, Icons.my_location, 'Service Radius', '${user.serviceRadius ?? 0} km'),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor)),
                Text(
                  value,
                  style: AppStyles.bodyLargeOf(context).copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
