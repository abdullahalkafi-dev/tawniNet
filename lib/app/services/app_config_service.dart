import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/api_client.dart';

/// Public settings the server controls (commission, minimums, support contacts,
/// minimum app version, legal version). Loaded once at start and refreshed on demand;
/// every value has a safe default so the app works if the call fails.
class AppConfigService extends GetxService {
  final feePercentage = 20.0.obs;
  final minimumServiceAmount = 0.0.obs;
  final supportEmail = ''.obs;
  final supportPhone = ''.obs;
  final supportWhatsapp = ''.obs;
  final appName = '3awniNet'.obs;
  final legalVersion = 1.obs;
  final termsText = ''.obs;
  final privacyText = ''.obs;

  /// Oldest app version the server still accepts ("" = no limit).
  final minAppVersion = ''.obs;

  /// Version of this installation, e.g. "1.0.0".
  final appVersion = ''.obs;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<AppConfigService> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion.value = info.version;
    } catch (_) {}
    await refresh();
    return this;
  }

  Future<void> refresh() async {
    try {
      final res = await Get.find<ApiClient>().get<dynamic>(
        ApiConstants.appConfig,
        queryParameters: {'lang': Get.locale?.languageCode ?? 'fr'},
        fromData: (d) => d,
      );
      final d = res.data;
      if (res.success && d is Map) {
        feePercentage.value = (d['platformFeePercentage'] as num?)?.toDouble() ?? feePercentage.value;
        minimumServiceAmount.value =
            (d['minimumServiceAmount'] as num?)?.toDouble() ?? minimumServiceAmount.value;
        supportEmail.value = d['supportEmail']?.toString() ?? '';
        supportPhone.value = d['supportPhone']?.toString() ?? '';
        supportWhatsapp.value = d['supportWhatsapp']?.toString() ?? '';
        appName.value = d['appName']?.toString().isNotEmpty == true
            ? d['appName'].toString()
            : appName.value;
        legalVersion.value = (d['legalVersion'] as num?)?.toInt() ?? 1;
        termsText.value = d['termsOfService']?.toString() ?? '';
        privacyText.value = d['privacyPolicy']?.toString() ?? '';
        minAppVersion.value = d['minAppVersion']?.toString() ?? '';
        _loaded = true;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Config] load failed: $e');
    }
  }

  /// True when this installation is older than the version the server requires.
  bool get updateRequired {
    final min = minAppVersion.value.trim();
    final cur = appVersion.value.trim();
    if (min.isEmpty || cur.isEmpty) return false;
    return _compare(cur, min) < 0;
  }

  static int _compare(String a, String b) {
    List<int> parts(String v) =>
        v.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
