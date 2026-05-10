import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/post_job_controller.dart';

class PostJobView extends GetView<PostJobController> {
  const PostJobView({super.key});

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
          'Post a job',
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Write a title for your job post'),
            _buildTextField(
              controller.titleController,
              'Type your job title...',
            ),
            const SizedBox(height: 20),
            _buildLabel('How long will your work take?'),
            _buildLabel('Preferred Date', isSub: true),
            _buildTextField(
              controller.dateController,
              'mm/dd/yyyy',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Start time', isSub: true),
                      _buildTextField(
                        controller.startTimeController,
                        '10:00 AM',
                        icon: Icons.unfold_more,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('End time', isSub: true),
                      _buildTextField(
                        controller.endTimeController,
                        '11:00 AM',
                        icon: Icons.unfold_more,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildLabel('Describe your job'),
            _buildTextField(
              controller.descController,
              'e.g., I need someone to assemble a new bookshelf.',
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            _buildLabel('Tell us your budget'),
            Row(
              children: [
                Expanded(
                  child: _buildBudgetOption(
                    'Hourly rate',
                    Icons.access_time,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBudgetOption(
                    'Fixed price',
                    Icons.label_outline,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(controller.budgetController, '\$0', prefix: '\$'),
            const SizedBox(height: 20),
            _buildLabel('Job Location'),
            _buildLabel('Street Address *', isSub: true),
            _buildTextField(
              controller.addressController,
              '123 Main Street',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),
            _buildLabel('Add photos (optional)'),
            _buildPhotoPicker(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: controller.postJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Post Request'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool isSub = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: isSub
            ? AppStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              )
            : AppStyles.h2.copyWith(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    IconData? icon,
    int maxLines = 1,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppStyles.bodyMedium.copyWith(color: Colors.grey[400]),
          prefixText: prefix,
          suffixIcon: icon != null
              ? Icon(icon, color: Colors.grey[400], size: 20)
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

  Widget _buildBudgetOption(String title, IconData icon, bool hourly) {
    return Obx(() {
      bool isSelected = controller.isHourly.value == hourly;
      return GestureDetector(
        onTap: () => controller.toggleBudget(hourly),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyMedium.copyWith(fontSize: 12),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : Colors.grey[300],
                size: 16,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPhotoPicker() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[200]!,
              style: BorderStyle.solid,
            ),
          ),
          child: Icon(Icons.add_a_photo_outlined, color: Colors.grey[400]),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=200',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
