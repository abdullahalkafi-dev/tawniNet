import 'package:awnneaapp/app/core/constants/app_info.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'profile_about'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(context, 'about_intro_title'.tr, 'about_intro_body'.tr),
            _buildSection(context, 'about_mission_title'.tr, 'about_mission_body'.tr),
            _buildSection(context, 'about_values_title'.tr, 'about_values_body'.tr),
            _buildSection(context, 'about_team_title'.tr, 'about_team_body'.tr),
            _buildSection(
              context,
              'about_contact_title'.tr,
              'about_contact_body'.trParams({
                'email': AppInfo.supportEmail,
                'phone': AppInfo.supportPhone,
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.h2Of(context).copyWith(fontSize: 16)),
          const SizedBox(height: 12),
          Text(content, style: AppStyles.bodyMediumOf(context).copyWith(height: 1.6, color: context.textSecondaryColor)),
        ],
      ),
    );
  }
}
