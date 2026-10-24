import 'package:url_launcher/url_launcher.dart';

/// Brand and support contact details shown in the app.
/// Keep in sync with the backend Settings defaults (supportEmail, contactPhone).
class AppInfo {
  AppInfo._();

  static const String brandName = '3awniNet';
  static const String supportEmail = 'support@3awninet.ma';
  static const String supportPhone = '+212 522 00 00 00';

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
