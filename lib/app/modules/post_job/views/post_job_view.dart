import 'dart:io';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/post_job_controller.dart';

class PostJobView extends GetView<PostJobController> {
  const PostJobView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'post_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(context, 'post_write_title'.tr),
            _buildTextField(
              context,
              controller.titleController,
              'post_type_title'.tr,
            ),
            const SizedBox(height: 20),

            _buildLabel(context, 'post_select_category'.tr),
            _buildCategoryDropdown(context),
            const SizedBox(height: 20),

            _buildLabel(context, 'post_how_long'.tr),
            _buildLabel(context, 'post_preferred_date'.tr, isSub: true),
            _buildTextField(
              context,
              controller.dateController,
              'mm/dd/yyyy',
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () => controller.pickDate(context),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context, 'post_start_time'.tr, isSub: true),
                      _buildTextField(
                        context,
                        controller.startTimeController,
                        '10:00 AM',
                        icon: Icons.unfold_more,
                        readOnly: true,
                        onTap: () => controller.pickTime(
                            context, controller.startTimeController),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context, 'post_end_time'.tr, isSub: true),
                      _buildTextField(
                        context,
                        controller.endTimeController,
                        '11:00 AM',
                        icon: Icons.unfold_more,
                        readOnly: true,
                        onTap: () => controller.pickTime(
                            context, controller.endTimeController),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel(context, 'post_describe'.tr),
            _buildTextField(
              context,
              controller.descController,
              'post_describe_hint'.tr,
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            _buildLabel(context, 'post_budget_title'.tr),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetOption(
                    context,
                    'post_hourly_rate'.tr,
                    Icons.access_time,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetOption(
                    context,
                    'post_fixed_price'.tr,
                    Icons.label_outline,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              context,
              controller.budgetController,
              '0',
              prefix: 'MAD',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),

            _buildLabel(context, 'post_job_location'.tr),
            _buildLabel(context, 'post_street_address'.tr, isSub: true),
            _buildLocationField(context),
            const SizedBox(height: 20),

            _buildLabel(context, 'post_add_photos'.tr),
            _buildPhotoPicker(context),
            const SizedBox(height: 40),

            Obx(() => SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? () {}
                    : controller.postJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('post_submit'.tr),
              ),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Category Dropdown ───────────────────────────────────

  Widget _buildCategoryDropdown(BuildContext context) {
    return Obx(() {
      final cats = controller.categories;
      if (cats.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: Text(
            'post_loading_categories'.tr,
            style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.inputFillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderSubtle),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: context.cardColor,
            value: controller.selectedCategory.value?.id,
            hint: Text(
              'post_select_category'.tr,
              style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            ),
            items: cats.map((cat) {
              return DropdownMenuItem<String>(
                value: cat.id,
                child: Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: AppStyles.bodyMediumOf(context),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? catId) {
              if (catId != null) {
                final selected = cats.firstWhere((c) => c.id == catId);
                controller.selectedCategory.value = selected;
              }
            },
          ),
        ),
      );
    });
  }

  // ─── Location Field with Autocomplete ────────────────────

  Widget _buildLocationField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        Container(
          decoration: BoxDecoration(
            color: context.inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderSubtle),
          ),
          child: TextField(
            controller: controller.addressController,
            onChanged: controller.searchAddress,
            style: TextStyle(color: context.textPrimaryColor),
            decoration: InputDecoration(
              hintText: 'post_search_location'.tr,
              hintStyle:
                  AppStyles.bodyMedium.copyWith(color: context.textHintColor),
              prefixIcon:
                  Icon(Icons.location_on_outlined, color: context.textHintColor, size: 20),
              suffixIcon: Obx(() => controller.isSearchingLocation.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const SizedBox.shrink()),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Use current location button
        GestureDetector(
          onTap: controller.useCurrentLocation,
          child: Row(
            children: [
              const Icon(Icons.send, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'post_use_location'.tr,
                style: AppStyles.bodyLargeOf(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Search results dropdown
        Obx(() {
          if (controller.searchResults.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final result = controller.searchResults[index];
                final displayName =
                    result['displayName'] as String? ?? '';
                return InkWell(
                  onTap: () => controller.selectSearchResult(result),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppStyles.bodyMediumOf(context).copyWith(
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────

  Widget _buildLabel(BuildContext context, String text, {bool isSub = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: isSub
            ? AppStyles.bodyMedium.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              )
            : AppStyles.h2Of(context).copyWith(fontSize: 16),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context,
    TextEditingController controller,
    String hint, {
    IconData? icon,
    int maxLines = 1,
    String? prefix,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.inputFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderSubtle),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: context.textPrimaryColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
          prefixText: prefix,
          prefixStyle: TextStyle(color: context.textPrimaryColor),
          suffixIcon: icon != null
              ? Icon(icon, color: context.textHintColor, size: 20)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetOption(BuildContext context, String title, IconData icon, bool hourly) {
    return Obx(() {
      bool isSelected = controller.isHourly.value == hourly;
      return GestureDetector(
        onTap: () => controller.toggleBudget(hourly),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : context.textHintColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 12),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : context.textHintColor,
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPhotoPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: controller.pickImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.inputFillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.borderSubtle,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child:
                      Icon(Icons.add_a_photo_outlined, color: context.textHintColor),
                ),
              ),
              Obx(
                () => Row(
                  children: controller.selectedImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImage(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          if (controller.selectedImages.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${controller.selectedImages.length}${'post_photos_selected'.tr}',
              style: AppStyles.bodyMedium.copyWith(
                color: context.textHintColor,
                fontSize: 12,
              ),
            ),
          );
        }),
      ],
    );
  }
}
