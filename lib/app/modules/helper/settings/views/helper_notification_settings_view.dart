import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelperNotificationSettingsView extends StatefulWidget {
  const HelperNotificationSettingsView({super.key});

  @override
  State<HelperNotificationSettingsView> createState() => _HelperNotificationSettingsViewState();
}

class _HelperNotificationSettingsViewState extends State<HelperNotificationSettingsView> {
  bool notificationOn = true;
  bool soundOn = true;
  bool vibrateOn = false;
  bool newServiceOn = true;

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
          style: AppStyles.h2.copyWith(fontSize: 20, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildToggleRow('Notification', notificationOn, (val) => setState(() => notificationOn = val)),
            _buildToggleRow('Sound', soundOn, (val) => setState(() => soundOn = val)),
            _buildToggleRow('Vibrate', vibrateOn, (val) => setState(() => vibrateOn = val)),
            _buildToggleRow('New Service Available', newServiceOn, (val) => setState(() => newServiceOn = val)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyLarge.copyWith(fontSize: 16)),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
