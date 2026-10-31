import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/app_config_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../constants/api_constants.dart';

/// A language the app ships translations for.
class AppLanguage {
  final Locale locale;
  final String nativeName;
  final String subtitle;
  final String flag;

  const AppLanguage({
    required this.locale,
    required this.nativeName,
    required this.subtitle,
    required this.flag,
  });

  /// Storage / translation-map key, e.g. `fr_FR`.
  String get code => '${locale.languageCode}_${locale.countryCode}';
}

class LocaleService extends GetxService {
  static const _storageKey = 'app_locale';

  /// Supported languages, in picker order. Keys must match AppTranslations.
  static const List<AppLanguage> languages = [
    AppLanguage(
      locale: Locale('ar', 'MA'),
      nativeName: 'العربية',
      subtitle: 'Moroccan Arabic (الدارجة)',
      flag: '🇲🇦',
    ),
    AppLanguage(
      locale: Locale('fr', 'FR'),
      nativeName: 'Français',
      subtitle: 'French',
      flag: '🇫🇷',
    ),
    AppLanguage(
      locale: Locale('en', 'US'),
      nativeName: 'English',
      subtitle: 'English (US)',
      flag: '🇺🇸',
    ),
    AppLanguage(
      locale: Locale('es', 'ES'),
      nativeName: 'Español',
      subtitle: 'Spanish',
      flag: '🇪🇸',
    ),
  ];

  static List<Locale> get supportedLocales =>
      languages.map((l) => l.locale).toList();

  final currentLocale = const Locale('fr', 'FR').obs;

  AppLanguage get currentLanguage => languages.firstWhere(
        (l) => l.locale.languageCode == currentLocale.value.languageCode,
        orElse: () => languages.firstWhere((l) => l.locale.languageCode == 'en'),
      );

  String get currentLanguageName => currentLanguage.nativeName;

  bool get isArabic => currentLocale.value.languageCode == 'ar';

  bool isSelected(AppLanguage language) =>
      language.locale.languageCode == currentLocale.value.languageCode;

  Future<LocaleService> init() async {
    try {
      final storage = Get.find<StorageService>();
      final saved = await storage.read(_storageKey);
      final match = languages.firstWhereOrNull((l) => l.code == saved);
      if (match != null) {
        currentLocale.value = match.locale;
        Get.updateLocale(match.locale);
      } else {
        // First launch: follow the phone's language (Arabic / French / Spanish / English),
        // French for anything else — the main language of the market.
        final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        final byDevice = languages.firstWhereOrNull((l) => l.locale.languageCode == device);
        final chosen = byDevice ?? languages.firstWhere((l) => l.locale.languageCode == 'fr');
        currentLocale.value = chosen.locale;
        Get.updateLocale(chosen.locale);
      }
    } catch (_) {}
    return this;
  }

  /// Moves to the next language in [languages].
  Future<void> toggleLocale() async {
    final index = languages.indexWhere(isSelected);
    await setLocale(languages[(index + 1) % languages.length].locale);
  }

  Future<void> setLocale(Locale locale) async {
    currentLocale.value = locale;
    Get.updateLocale(locale);
    try {
      final storage = Get.find<StorageService>();
      await storage.write(
        _storageKey,
        '${locale.languageCode}_${locale.countryCode}',
      );
    } catch (_) {}
    unawaited(syncToServer());
    if (Get.isRegistered<AppConfigService>()) unawaited(Get.find<AppConfigService>().refresh());
  }

  /// Tell the server which language to use for push notifications and messages.
  Future<void> syncToServer() async {
    try {
      if (!Get.isRegistered<AuthService>() || !Get.find<AuthService>().isLoggedIn.value) return;
      await Get.find<ApiClient>().patch(
        ApiConstants.userMe,
        data: {'locale': currentLocale.value.languageCode},
      );
    } catch (_) {
      // Not critical: it is sent again on the next language change / login.
    }
  }
}
