import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';

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

  final currentLocale = const Locale('en', 'US').obs;

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
  }
}
