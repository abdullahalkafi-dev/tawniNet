import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/core/widgets/custom_text_field.dart';
import 'package:awnneaapp/app/services/auth_service.dart';

/// Change the password while signed in. The server ends the sessions on other
/// devices and gives this device a fresh login.
class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({super.key});

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty) {
      AppFeedback.error('password_current_required'.tr);
      return;
    }
    if (_next.text.length < kMinPasswordLength) {
      AppFeedback.error('err_password_too_short'.trParams({'min': '$kMinPasswordLength'}));
      return;
    }
    if (_next.text != _confirm.text) {
      AppFeedback.error('ui_passwords_do_not_match'.tr);
      return;
    }
    if (_next.text == _current.text) {
      AppFeedback.error('err_same_password'.tr);
      return;
    }
    setState(() => _busy = true);
    try {
      await Get.find<AuthService>().changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      Get.back();
      AppFeedback.success('password_changed_msg'.tr, title: 'password_changed_title'.tr);
    } catch (e) {
      AppFeedback.error(AppSnackbar.extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: Text('password_change_title'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'password_change_hint'.trParams({'min': '$kMinPasswordLength'}),
              style: AppStyles.bodyMediumOf(context).copyWith(color: context.textSecondaryColor),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'password_current'.tr,
              hint: 'password_current'.tr,
              isPassword: true,
              isVisible: _showCurrent,
              onToggleVisibility: () => setState(() => _showCurrent = !_showCurrent),
              controller: _current,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'password_new'.tr,
              hint: 'password_new'.tr,
              isPassword: true,
              isVisible: _showNext,
              onToggleVisibility: () => setState(() => _showNext = !_showNext),
              controller: _next,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'auth_confirm_password'.tr,
              hint: 'auth_confirm_password'.tr,
              isPassword: true,
              isVisible: _showNext,
              onToggleVisibility: () => setState(() => _showNext = !_showNext),
              controller: _confirm,
            ),
            const SizedBox(height: 32),
            CustomButton(text: 'btn_save'.tr, onPressed: _submit, isLoading: _busy),
          ],
        ),
      ),
    );
  }
}
