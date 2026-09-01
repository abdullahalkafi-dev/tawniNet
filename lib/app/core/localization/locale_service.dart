import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/storage_service.dart';

class LocaleService extends GetxService {
  static const _storageKey = 'app_locale';
  final currentLocale = const Locale('en', 'US').obs;

  String get currentLanguageName =>
      currentLocale.value.languageCode == 'ar' ? 'العربية' : 'English';

  bool get isArabic => currentLocale.value.languageCode == 'ar';

  Future<LocaleService> init() async {
    try {
      final storage = Get.find<StorageService>();
      final saved = await storage.read(_storageKey);
      if (saved == 'ar_MA') {
        currentLocale.value = const Locale('ar', 'MA');
        Get.updateLocale(currentLocale.value);
      }
    } catch (_) {}
    return this;
  }

  Future<void> toggleLocale() async {
    final newLocale = currentLocale.value.languageCode == 'en'
        ? const Locale('ar', 'MA')
        : const Locale('en', 'US');
    currentLocale.value = newLocale;
    Get.updateLocale(newLocale);
    try {
      final storage = Get.find<StorageService>();
      await storage.write(
        _storageKey,
        newLocale == const Locale('ar', 'MA') ? 'ar_MA' : 'en_US',
      );
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    currentLocale.value = locale;
    Get.updateLocale(locale);
    try {
      final storage = Get.find<StorageService>();
      await storage.write(
        _storageKey,
        locale == const Locale('ar', 'MA') ? 'ar_MA' : 'en_US',
      );
    } catch (_) {}
  }
}
