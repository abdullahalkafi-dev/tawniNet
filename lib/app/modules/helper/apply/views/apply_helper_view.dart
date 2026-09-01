import 'dart:io';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/core/widgets/custom_text_field.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/apply_helper_controller.dart';

class ApplyHelperView extends GetView<ApplyHelperController> {
  const ApplyHelperView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.redAccent),
          onPressed: () => _showLogoutDialog(context),
        ),
        title: Text(
          'apply_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(
                'apply_personal'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.h2Of(context).copyWith(
                  fontSize: 24,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'apply_subtitle'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
            _buildAvatarSection(context),
            const SizedBox(height: 24),
            _buildRequiredField(context, 'apply_full_name'.tr, 'apply_enter_name'.tr, controller.fullNameController, readOnly: true),
            const SizedBox(height: 16),
            _buildRequiredField(context, 'apply_age'.tr, 'apply_enter_age'.tr, controller.ageController),
            const SizedBox(height: 4),
            Text(
              'apply_age_requirement'.tr,
              style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
            ),
            const SizedBox(height: 16),
            _buildRequiredField(
              context,
              'apply_city'.tr,
              'apply_city_hint'.tr,
              controller.cityController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
            ),
            const SizedBox(height: 16),
            _buildRequiredField(context, 'apply_phone'.tr, '+212600000000', controller.phoneController, readOnly: true),
            const SizedBox(height: 16),
            _buildRequiredField(context, 'apply_email'.tr, 'your.email@example.com', controller.emailController, readOnly: false, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildDropdownField(
              context: context,
              label: 'apply_language'.tr,
              value: controller.selectedLanguage,
              items: controller.languages,
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdownField(
              context: context,
              label: 'apply_service_type'.tr,
              selected: controller.selectedServiceType,
              categories: controller.categories,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'apply_price_hour'.tr,
              hint: 'apply_set_price'.tr,
              controller: controller.priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'apply_experience'.tr,
              hint: 'apply_type_experience'.tr,
              controller: controller.experienceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'apply_radius'.tr,
              hint: 'apply_service_area'.tr,
              controller: controller.serviceRadiusController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'apply_bio'.tr,
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.bioController,
                  maxLines: 8,
                  minLines: 5,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'apply_enter_bio'.tr,
                    hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                    filled: true,
                    fillColor: context.inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPhotoUploadSection(context),
            const SizedBox(height: 20),
            _buildDocumentUploadSection(context),
            const SizedBox(height: 24),
            Obx(() => CustomButton(
              text: controller.isLoading.value ? 'apply_submitting'.tr : 'apply_submit'.tr,
              onPressed: controller.isLoading.value ? () {} : controller.submitApplication,
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: context.textHintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'apply_safe_info'.tr,
                    style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textSecondaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
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
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
            ),
            const SizedBox(height: 16),
            Text('apply_logout_title'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'apply_logout_confirm'.tr,
              style: AppStyles.bodyMedium.copyWith(color: context.textSecondaryColor),
              textAlign: TextAlign.center,
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
                    onPressed: () {
                      Get.back();
                      controller.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('apply_logout'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequiredField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: '$label ',
            style: AppStyles.bodyMediumOf(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            filled: true,
            fillColor: readOnly ? context.inputFillLight : context.inputFillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: readOnly
                  ? BorderSide(color: context.borderSubtle)
                  : const BorderSide(color: AppColors.primary, width: 2),
            ),
            suffixIcon: readOnly
                ? Icon(Icons.lock_outline, size: 18, color: context.textHintColor)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: controller.pickProfilePhoto,
        child: Stack(
          children: [
            Obx(() {
              final photoPath = controller.profilePhotoPath.value;
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.cardColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photoPath != null
                      ? Image.file(
                          File(photoPath),
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        )
                      : Container(
                          color: context.inputFillLight,
                          child: Icon(Icons.person, size: 40, color: context.textHintColor),
                        ),
                ),
              );
            }),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required String label,
    required RxString value,
    required List<String> items,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyMediumOf(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.inputFillColor,
            border: Border.all(color: context.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.value.isEmpty ? null : value.value,
              dropdownColor: context.cardColor,
              hint: Text(
                hint ?? 'Select',
                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: TextStyle(color: context.textPrimaryColor)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) value.value = newValue;
              },
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCategoryDropdownField({
    required BuildContext context,
    required String label,
    required Rxn<Category> selected,
    required List<Category> categories,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: '$label ',
            style: AppStyles.bodyMediumOf(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
            children: const [
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.inputFillColor,
            border: Border.all(color: context.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Category>(
              value: selected.value,
              dropdownColor: context.cardColor,
              borderRadius: BorderRadius.circular(14),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.textSecondaryColor),
              hint: Text(
                'apply_select_service'.tr,
                style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              ),
              isExpanded: true,
              selectedItemBuilder: (BuildContext ctx) {
                return categories.map((Category category) {
                  return Row(
                    children: [
                      _buildCategoryIcon(category, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
              items: categories.map((Category category) {
                return DropdownMenuItem<Category>(
                  value: category,
                  child: Row(
                    children: [
                      _buildCategoryIcon(category, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Category? newValue) {
                selected.value = newValue;
              },
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCategoryIcon(Category category, {double size = 18}) {
    final iconUrl = category.resolvedIconUrl;
    return Container(
      width: size + 12,
      height: size + 12,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: (iconUrl != null && iconUrl.isNotEmpty)
            ? Image.network(
                iconUrl,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  category.icon,
                  size: size,
                  color: category.color,
                ),
              )
            : Icon(
                category.icon,
                size: size,
                color: category.color,
              ),
      ),
    );
  }

  Widget _buildPhotoUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'helper_add_photos'.tr,
          style: AppStyles.bodyMediumOf(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final photos = controller.selectedPhotoPaths;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Add photo button
              GestureDetector(
                onTap: controller.pickPhotos,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    border: Border.all(color: context.borderSubtle, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: controller.isUploadingPhoto.value
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.camera_alt_outlined, color: context.textHintColor, size: 28),
                ),
              ),
              // Photo thumbnails
              ...photos.asMap().entries.map((entry) {
                final index = entry.key;
                final path = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => controller.removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDocumentUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Automated Didit KYC Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0D9488).withOpacity(0.08),
                const Color(0xFF0D9488).withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: Color(0xFF0D9488), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Automated Moroccan ID Verification',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Fast biometric & Moroccan ID scan powered by Didit',
                          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() {
                final isStarting = controller.isStartingKyc.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isStarting ? null : controller.launchDiditKyc,
                    icon: isStarting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                    label: Text(
                      isStarting ? 'Starting Session...' : 'Verify Moroccan ID with Didit',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildDropdownField(
          context: context,
          label: 'apply_upload_photo'.tr,
          value: controller.selectedIdType,
          items: controller.idTypes,
        ),
        const SizedBox(height: 12),
        Obx(() {
          final hasDoc = controller.documentPath.value != null;
          if (hasDoc) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.inputFillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.documentFileName.value ?? 'Document',
                          style: AppStyles.bodyLargeOf(context).copyWith(fontSize: 14),
                        ),
                        Text(
                          controller.documentFileSize.value ?? '',
                          style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: controller.removeDocument,
                  ),
                ],
              ),
            );
          }
          return GestureDetector(
            onTap: controller.pickDocument,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                border: Border.all(color: AppColors.primary, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'apply_upload_document'.tr,
                    style: AppStyles.bodyLargeOf(context).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'apply_upload_hint'.tr,
                    style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.pickDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Text('apply_upload_btn'.tr, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'apply_upload_desc'.tr,
          style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
        ),
      ],
    );
  }
}
