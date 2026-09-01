import 'dart:io';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late TextEditingController nameCtl;
  late TextEditingController emailCtl;
  late TextEditingController phoneCtl;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ProfileController>();
    nameCtl = TextEditingController(text: controller.name.value);
    emailCtl = TextEditingController(text: controller.email.value);
    phoneCtl = TextEditingController(text: controller.phone.value);
  }

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    phoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'edit_profile_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarSection(context, controller),
            const SizedBox(height: 32),
            _buildTextField(context, 'edit_full_name'.tr, nameCtl),
            const SizedBox(height: 16),
            _buildTextField(context, 'edit_email'.tr, emailCtl, readOnly: true),
            const SizedBox(height: 16),
            _buildTextField(context, 'edit_phone'.tr, phoneCtl),
            const SizedBox(height: 16),
            _buildGenderDropdown(context, controller),
            const SizedBox(height: 24),
            Text(
              'edit_address'.tr,
              style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => Text(
                    controller.address.value.isNotEmpty
                        ? controller.address.value
                        : 'edit_no_address'.tr,
                    style: AppStyles.bodyMedium.copyWith(
                      color: controller.address.value.isNotEmpty
                          ? context.textSecondaryColor
                          : context.textHintColor,
                    ),
                  )),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: context.textHintColor,
                    size: 20,
                  ),
                  onPressed: () => _showAddressDialog(context, controller),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showAddressDialog(context, controller),
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              label: Text(
                'edit_add_address'.tr,
                style: AppStyles.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 40),
            Obx(() => SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: controller.isUpdating.value
                    ? null
                    : () async {
                        controller.name.value = nameCtl.text.trim();
                        controller.phone.value = phoneCtl.text.trim();
                        await controller.updateProfile(
                          newName: nameCtl.text.trim(),
                          newPhone: phoneCtl.text.trim(),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: controller.isUpdating.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'edit_update'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, ProfileController controller) {
    final user = Get.find<AuthService>().currentUser.value;
    final avatar = user?.avatar;

    return Center(
      child: Obx(() => Stack(
        children: [
          Container(
            width: 110,
            height: 110,
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
              child: controller.pickedAvatarPath != null
                  ? Image.file(
                      File(controller.pickedAvatarPath!),
                      fit: BoxFit.cover,
                    )
                  : avatar != null && avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarPlaceholder(context);
                          },
                        )
                      : _buildAvatarPlaceholder(context),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: controller.isUploadingAvatar.value
                  ? null
                  : () => controller.pickAndUploadAvatar(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF5AB9A7),
                  shape: BoxShape.circle,
                ),
                child: controller.isUploadingAvatar.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Container(
      color: context.inputFillLight,
      child: Icon(Icons.person, size: 50, color: context.textHintColor),
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController ctl, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: TextField(
            controller: ctl,
            readOnly: readOnly,
            style: TextStyle(color: context.textPrimaryColor),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddressDialog(BuildContext context, ProfileController controller) {
    final addressController = TextEditingController(text: controller.address.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('edit_update_address'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        content: TextField(
          controller: addressController,
          maxLines: 2,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'edit_enter_address'.tr,
            hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            filled: true,
            fillColor: context.inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSecondary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('btn_cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAddress = addressController.text.trim();
              Navigator.pop(context);
              await controller.updateProfile(newAddress: newAddress);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('btn_save'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown(BuildContext context, ProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'edit_gender'.tr,
          style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 48,
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.gender.value,
              isExpanded: true,
              dropdownColor: context.cardColor,
              icon: Icon(Icons.keyboard_arrow_down, color: context.textHintColor),
              items: [
                DropdownMenuItem(value: 'Male', child: Text('edit_male'.tr, style: TextStyle(color: context.textPrimaryColor))),
                DropdownMenuItem(value: 'Female', child: Text('edit_female'.tr, style: TextStyle(color: context.textPrimaryColor))),
                DropdownMenuItem(value: 'Other', child: Text('edit_other'.tr, style: TextStyle(color: context.textPrimaryColor))),
              ].toList(),
              onChanged: (val) => controller.gender.value = val!,
            ),
          ),
        ),
      ],
    );
  }
}
