import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awnneaapp/app/services/app_config_service.dart';

/// Brand and support contact details shown in the app. The live values come from
/// the server settings (admin dashboard → Settings); the defaults only apply
/// until they are loaded.
class AppInfo {
  AppInfo._();

  static const String brandName = '3awniNet';
  static const String _defaultEmail = 'support@3awninet.ma';
  static const String _defaultPhone = '+212 522 00 00 00';

  static AppConfigService? get _cfg =>
      Get.isRegistered<AppConfigService>() ? Get.find<AppConfigService>() : null;

  static String get supportEmail {
    final v = _cfg?.supportEmail.value ?? '';
    return v.isNotEmpty ? v : _defaultEmail;
  }

  static String get supportPhone {
    final v = _cfg?.supportPhone.value ?? '';
    return v.isNotEmpty ? v : _defaultPhone;
  }

  /// Empty when the platform has no WhatsApp support line.
  static String get supportWhatsapp => _cfg?.supportWhatsapp.value ?? '';

  static Future<void> emailSupport() async {
    final uri = Uri(scheme: 'mailto', path: supportEmail);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static Future<void> callSupport() async {
    final uri = Uri(scheme: 'tel', path: supportPhone.replaceAll(' ', ''));
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}
