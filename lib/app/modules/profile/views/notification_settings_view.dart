import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class NotificationSettingsView extends GetView<ProfileController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'notif_title'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            _buildToggleItem(context, 'notif_title'.tr, controller.notificationEnabled),
            _buildToggleItem(context, 'notif_sound'.tr, controller.soundEnabled),
            _buildToggleItem(context, 'notif_vibrate'.tr, controller.vibrateEnabled),
            _buildToggleItem(context, 'notif_payments'.tr, controller.paymentsEnabled),
            _buildToggleItem(context, 'notif_cashback'.tr, controller.cashbackEnabled),
            _buildToggleItem(context, 'notif_app_updates'.tr, controller.appUpdatesEnabled),
            _buildToggleItem(
              context,
              'notif_new_service'.tr,
              controller.newServiceEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(BuildContext context, String title, RxBool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppStyles.bodyLargeOf(context).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Obx(
            () => Switch(
              value: value.value,
              onChanged: (val) => value.value = val,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: context.isDarkMode ? AppColors.darkBorder : Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}
