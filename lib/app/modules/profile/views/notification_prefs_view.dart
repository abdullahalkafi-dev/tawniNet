import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/auth_service.dart';

/// Notification switches, saved on the server (so they apply to every device
/// and to the push messages the server sends). Used by clients and helpers.
class NotificationPrefsView extends StatefulWidget {
  const NotificationPrefsView({super.key});

  @override
  State<NotificationPrefsView> createState() => _NotificationPrefsViewState();
}

class _NotificationPrefsViewState extends State<NotificationPrefsView> {
  // Only switches the server really applies (it decides whether to send the push at all).
  static const _keys = ['push', 'payments', 'appUpdates', 'newService'];

  late final Map<String, bool> _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final saved = Get.find<AuthService>().currentUser.value?.notificationPrefs ?? const {};
    _prefs = {for (final k in _keys) k: saved[k] ?? true};
  }

  String _label(String key) {
    switch (key) {
      case 'push':
        return 'notif_title'.tr;
      case 'payments':
        return 'notif_payments'.tr;
      case 'appUpdates':
        return 'notif_app_updates'.tr;
      default:
        return 'notif_new_service'.tr;
    }
  }

  Future<void> _toggle(String key, bool value) async {
    final before = _prefs[key] ?? true;
    setState(() {
      _prefs[key] = value;
      _saving = true;
    });
    try {
      await Get.find<AuthService>().saveNotificationPrefs({key: value});
    } catch (e) {
      // Not saved: put the switch back and say why.
      if (mounted) setState(() => _prefs[key] = before);
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pushOn = _prefs['push'] ?? true;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: Text('notif_title'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        centerTitle: true,
        bottom: _saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        children: [
          for (final key in _keys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _label(key),
                      style: AppStyles.bodyLargeOf(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: key != 'push' && !pushOn ? context.textHintColor : null,
                      ),
                    ),
                  ),
                  Switch(
                    value: _prefs[key] ?? true,
                    onChanged: (key != 'push' && !pushOn) ? null : (v) => _toggle(key, v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor:
                        context.isDarkMode ? AppColors.darkBorder : Colors.grey[300],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
