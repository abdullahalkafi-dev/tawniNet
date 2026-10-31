import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/core/widgets/app_dialogs.dart';
import 'package:awnneaapp/app/core/widgets/custom_button.dart';
import 'package:awnneaapp/app/core/widgets/custom_text_field.dart';
import 'package:awnneaapp/app/services/auth_service.dart';

/// Delete the account (anonymises the personal data). Needs the password; the
/// server refuses while a job is in progress or the wallet still holds money,
/// and says why.
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  final _password = TextEditingController();
  bool _show = false;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      AppFeedback.error('password_current_required'.tr);
      return;
    }
    final ok = await AppDialogs.confirm(
      title: 'delete_account_confirm_title'.tr,
      message: 'delete_account_confirm_body'.tr,
      confirmLabel: 'delete_account_confirm_button'.tr,
      danger: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    try {
      // On success the app signs out and returns to the start screen.
      await Get.find<AuthService>().deleteAccount(_password.text);
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
        title: Text('delete_account_title'.tr, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                'delete_account_warning'.tr,
                style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'password_current'.tr,
              hint: 'password_current'.tr,
              isPassword: true,
              isVisible: _show,
              onToggleVisibility: () => setState(() => _show = !_show),
              controller: _password,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'delete_account_button'.tr,
              onPressed: _delete,
              isLoading: _busy,
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
