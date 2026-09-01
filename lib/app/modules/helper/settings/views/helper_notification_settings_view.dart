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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'settings_notification'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildToggleRow(context, 'notif_title'.tr, notificationOn, (val) => setState(() => notificationOn = val)),
            _buildToggleRow(context, 'notif_sound'.tr, soundOn, (val) => setState(() => soundOn = val)),
            _buildToggleRow(context, 'notif_vibrate'.tr, vibrateOn, (val) => setState(() => vibrateOn = val)),
            _buildToggleRow(context, 'notif_new_service'.tr, newServiceOn, (val) => setState(() => newServiceOn = val)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(BuildContext context, String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyLargeOf(context).copyWith(fontSize: 16)),
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
