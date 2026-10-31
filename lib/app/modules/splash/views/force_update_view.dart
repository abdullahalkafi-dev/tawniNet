import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/values/app_styles.dart';
import '../../../services/app_config_service.dart';

/// Shown when the server requires a newer version of the app than the one installed.
class ForceUpdateView extends StatelessWidget {
  const ForceUpdateView({super.key});

  Future<void> _openStore() async {
    // The store pages are set in the release; until then the web page of the app is used.
    final target = !kIsWeb && Platform.isIOS
        ? 'https://apps.apple.com/'
        : 'https://play.google.com/store/apps';
    try {
      await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final config = Get.find<AppConfigService>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update, size: 72, color: AppColors.primary),
                  const SizedBox(height: 24),
                  Text(
                    'update_required_title'.tr,
                    textAlign: TextAlign.center,
                    style: AppStyles.h1Of(context).copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'update_required_body'.trParams({
                      'version': config.minAppVersion.value,
                    }),
                    textAlign: TextAlign.center,
                    style: AppStyles.bodyMediumOf(context).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _openStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('update_required_button'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
