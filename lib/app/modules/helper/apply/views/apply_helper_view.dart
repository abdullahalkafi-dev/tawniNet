import 'package:cached_network_image/cached_network_image.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'dart:io';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/core/widgets/error_retry.dart';
import 'package:awnneaapp/app/core/widgets/helper_form_fields.dart';
import 'package:awnneaapp/app/core/widgets/custom_text_field.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          'ui_helper_application'.tr,
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ui_step_1_of_2_profile_services'.tr,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'ui_personal_work_details'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.h2Of(context).copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'ui_please_provide_your_service_details_all_informat'.tr,
                textAlign: TextAlign.center,
                style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            _buildAvatarSection(context),
            const SizedBox(height: 24),
            _buildRequiredField(context, 'ui_full_name'.tr, 'apply_enter_name'.tr, controller.fullNameController, readOnly: true),
            const SizedBox(height: 16),
            _buildRequiredField(
              context,
              'apply_age_label'.tr,
              'ui_enter_your_age_13'.tr,
              controller.ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ui_must_be_13_years_or_older_to_2'.tr,
              style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
            ),
            const SizedBox(height: 16),
            Obx(() => CityDropdown(
                  value: controller.selectedCity.value,
                  onChanged: (c) => controller.selectedCity.value = c,
                )),
            const SizedBox(height: 16),
            _buildRequiredField(context, 'ui_phone_number'.tr, '+212600000000', controller.phoneController, readOnly: true),
            const SizedBox(height: 16),
            _buildOptionalField(
              context,
              'apply_email'.tr,
              'your.email@example.com',
              controller.emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Obx(() => LanguageChips(
                  selected: controller.selectedLanguages.toList(),
                  onToggle: (lang, on) {
                    if (on) {
                      controller.selectedLanguages.add(lang);
                    } else {
                      controller.selectedLanguages.remove(lang);
                    }
                  },
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.categoriesFailed.value) {
                return ErrorRetry(minHeight: 120, onRetry: controller.fetchCategories);
              }
              return _buildCategoryDropdownField(
                context: context,
                label: 'ui_service_category'.tr,
                selected: controller.selectedServiceType,
                categories: controller.categories,
              );
            }),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'ui_hourly_rate_mad'.tr,
              hint: 'e.g. 100',
              controller: controller.priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            Obx(() {
              final category = controller.selectedServiceType.value;
              final min = category?.minHourlyRate;
              if (category == null || min == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'price_min_hourly'.trParams({
                    'category': category.name,
                    'min': min.toStringAsFixed(0),
                  }),
                  style: AppStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    color: context.textHintColor,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'ui_experience_years'.tr,
              hint: 'e.g. 3',
              controller: controller.experienceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'ui_service_radius_km'.tr,
              hint: 'e.g. 15',
              controller: controller.serviceRadiusController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ui_bio_optional'.tr,
                  style: AppStyles.bodyMediumOf(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.bioController,
                  maxLines: 5,
                  minLines: 3,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'ui_introduce_yourself_and_your_skills_to_clients'.tr,
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
            const SizedBox(height: 28),

            // Next: Verify Identity Button
            Obx(() => CustomButton(
              text: controller.isLoading.value
                  ? 'ui_saving_information'.tr
                  : 'ui_next_verify_identity'.tr,
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: controller.isLoading.value
                  ? () {}
                  : controller.submitFormStep,
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: context.textHintColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ui_step_2_will_require_scanning_your_moroccan'.tr,
                    style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textSecondaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
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
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.power_settings_new, color: Colors.redAccent, size: 30),
            ),
            const SizedBox(height: 16),
            Text('ui_logout_confirmation'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'ui_are_you_sure_you_want_to_log'.tr,
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
                    child: Text('profile_logout'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    TextEditingController textCtl, {
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
          controller: textCtl,
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

  Widget _buildOptionalField(
    BuildContext context,
    String label,
    String hint,
    TextEditingController textCtl, {
    TextInputType? keyboardType,
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
        TextFormField(
          controller: textCtl,
          keyboardType: keyboardType,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            filled: true,
            fillColor: context.inputFillColor,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: controller.pickProfilePhoto,
            child: Stack(
              children: [
                Obx(() {
                  final photoPath = controller.profilePhotoPath.value;
                  final photoKey = controller.profilePhotoKey.value;

                  ImageProvider? imageProvider;
                  if (photoPath != null) {
                    imageProvider = FileImage(File(photoPath));
                  } else if (photoKey != null && photoKey.isNotEmpty) {
                    final resolved = ApiConstants.resolveImageUrl(photoKey);
                    if (resolved != null && resolved.isNotEmpty) {
                      imageProvider = CachedNetworkImageProvider(resolved);
                    }
                  }

                  return Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.cardColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageProvider != null
                          ? Image(
                              image: imageProvider,
                              fit: BoxFit.cover,
                              width: 105,
                              height: 105,
                            )
                          : Container(
                              color: context.inputFillLight,
                              child: Icon(Icons.person, size: 50, color: context.textHintColor),
                            ),
                    ),
                  );
                }),
                PositionedDirectional(
                  bottom: 2,
                  end: 2,
                  child: Container(
                    padding: const EdgeInsets.all(7),
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
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: 'ui_profile_photo'.tr,
              style: AppStyles.bodyMediumOf(context).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
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
                'ui_select_service_category'.tr,
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
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Category? newCategory) {
                if (newCategory != null) selected.value = newCategory;
              },
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildCategoryIcon(Category category, {double size = 20}) {
    if (category.iconUrl != null && category.iconUrl!.isNotEmpty) {
      if (category.iconUrl!.endsWith('.svg')) {
        return SvgPicture.network(
          category.iconUrl!,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(category.color, BlendMode.srcIn),
          placeholderBuilder: (context) => Icon(category.icon, size: size, color: category.color),
        );
      }
      return AppNetworkImage(url: category.iconUrl!, width: size, height: size);
    }
    return Icon(category.icon, size: size, color: category.color);
  }

  Widget _buildPhotoUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'apply_work_photos_label'.tr,
          style: AppStyles.bodyMediumOf(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'apply_work_photos_hint'.tr,
          style: AppStyles.bodyMedium.copyWith(
            fontSize: 12,
            color: context.textHintColor,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final count = controller.selectedPhotoPaths.length + controller.uploadedPhotoKeys.length;
          return Column(
            children: [
              if (count < 5)
                GestureDetector(
                  onTap: controller.pickPhotos,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      border: Border.all(color: context.borderSubtle),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 36, color: context.textHintColor),
                        const SizedBox(height: 8),
                        Text(
                          'apply_upload_work_photos'.trParams({'count': '$count'}),
                          style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
                        ),
                      ],
                    ),
                  ),
                ),
              if (count > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: count,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isUploaded = index < controller.uploadedPhotoKeys.length;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isUploaded
                                ? AppNetworkImage(url: ApiConstants.resolveImageUrl(controller.uploadedPhotoKeys[index]) ?? '', width: 90, height: 90, fit: BoxFit.cover)
                                : Stack(
                                    children: [
                                      Image.file(
                                        File(controller.selectedPhotoPaths[index - controller.uploadedPhotoKeys.length]),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned.fill(
                                        child: Container(
                                          color: Colors.black26,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          PositionedDirectional(
                            top: 4,
                            end: 4,
                            child: GestureDetector(
                              onTap: () => controller.removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }
}
