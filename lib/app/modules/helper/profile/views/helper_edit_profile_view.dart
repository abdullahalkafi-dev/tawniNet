import 'dart:io';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HelperEditProfileView extends StatefulWidget {
  const HelperEditProfileView({super.key});

  @override
  State<HelperEditProfileView> createState() => _HelperEditProfileViewState();
}

class _HelperEditProfileViewState extends State<HelperEditProfileView> {
  late TextEditingController nameCtl;
  late TextEditingController emailCtl;
  late TextEditingController phoneCtl;
  late TextEditingController bioCtl;
  final isSaving = false.obs;
  final isUploadingAvatar = false.obs;
  final _picker = ImagePicker();
  String? _pickedAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthService>().currentUser.value;
    nameCtl = TextEditingController(text: user?.name ?? '');
    emailCtl = TextEditingController(text: user?.email ?? '');
    phoneCtl = TextEditingController(text: user?.phone ?? '');
    bioCtl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    nameCtl.dispose();
    emailCtl.dispose();
    phoneCtl.dispose();
    bioCtl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() => _pickedAvatarPath = image.path);
      isUploadingAvatar.value = true;

      final key = await _uploadFile(image.path);
      if (key != null) {
        final api = Get.find<ApiClient>();
        final response = await api.patch(
          ApiConstants.userMe,
          data: {'avatar': key},
        );

        if (response.success) {
          await Get.find<AuthService>().getMe();
          if (mounted) {
            Get.snackbar(
              'Success',
              'Profile photo updated',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } else {
          if (mounted) {
            Get.snackbar(
              'Error',
              response.message ?? 'Failed to update photo',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Failed to upload image',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to pick image',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<String?> _uploadFile(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final api = Get.find<ApiClient>();
      final response = await api.upload(
        ApiConstants.uploadImage,
        formData: formData,
      );

      if (response.success && response.data != null) {
        return response.data['key'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    isSaving.value = true;
    try {
      final api = Get.find<ApiClient>();
      final response = await api.patch(
        ApiConstants.userMe,
        data: {
          if (nameCtl.text.trim().isNotEmpty) 'name': nameCtl.text.trim(),
          if (phoneCtl.text.trim().isNotEmpty) 'phone': phoneCtl.text.trim(),
          if (bioCtl.text.trim().isNotEmpty) 'bio': bioCtl.text.trim(),
        },
      );

      if (response.success) {
        await Get.find<AuthService>().getMe();
        if (mounted) {
          Get.back();
          Get.snackbar(
            'Success',
            'Profile updated successfully',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            response.message ?? 'Update failed',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSaving.value = false;
    }
  }

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
          'helper_edit_profile'.tr,
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildAvatarSection(),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('helper_personal_info'.tr, style: AppStyles.h2.copyWith(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            _buildField('apply_full_name'.tr, nameCtl),
            const SizedBox(height: 16),
            _buildField('apply_email'.tr, emailCtl, readOnly: true),
            const SizedBox(height: 16),
            _buildField('helper_phone'.tr, phoneCtl),
            const SizedBox(height: 16),
            _buildBioField(),
            const SizedBox(height: 30),
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
                  child: Obx(() => ElevatedButton(
                    onPressed: isSaving.value ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isSaving.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('helper_save_changes'.tr, style: AppStyles.buttonText),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final user = Get.find<AuthService>().currentUser.value;
    final avatar = user?.avatar;

    return Center(
      child: Obx(() => Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: ClipOval(
              child: _pickedAvatarPath != null
                  ? Image.file(
                      File(_pickedAvatarPath!),
                      fit: BoxFit.cover,
                    )
                  : avatar != null && avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: isUploadingAvatar.value ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF5AB9A7),
                  shape: BoxShape.circle,
                ),
                child: isUploadingAvatar.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }

  Widget _buildField(String label, TextEditingController ctl, {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctl,
          readOnly: readOnly,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'helper_bio'.tr,
          style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: bioCtl,
          maxLines: 8,
          minLines: 5,
          decoration: InputDecoration(
            hintText: 'helper_enter_bio'.tr,
            hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
