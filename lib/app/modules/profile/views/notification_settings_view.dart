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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notification',
          style: AppStyles.h2.copyWith(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            _buildToggleItem('Notification', controller.notificationEnabled),
            _buildToggleItem('Sound', controller.soundEnabled),
            _buildToggleItem('Vibrate', controller.vibrateEnabled),
            _buildToggleItem('Payments', controller.paymentsEnabled),
            _buildToggleItem('Cashback', controller.cashbackEnabled),
            _buildToggleItem('App Updates', controller.appUpdatesEnabled),
            _buildToggleItem(
              'New Service Available',
              controller.newServiceEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(String title, RxBool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppStyles.bodyLarge.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Obx(
            () => Switch(
              value: value.value,
              onChanged: (val) => value.value = val,
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary.withOpacity(0.5),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }
}
