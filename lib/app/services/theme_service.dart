import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class ThemeService extends GetxService {
  static ThemeService get to => Get.find<ThemeService>();
  static const _storageKey = 'app_theme_mode';

  final themeMode = ThemeMode.system.obs;

  Future<ThemeService> init() async {
    try {
      final storage = Get.find<StorageService>();
      final saved = await storage.read(_storageKey);
      if (saved == 'dark') {
        themeMode.value = ThemeMode.dark;
      } else if (saved == 'light') {
        themeMode.value = ThemeMode.light;
      } else {
        themeMode.value = ThemeMode.system;
      }
    } catch (_) {
      themeMode.value = ThemeMode.system;
    }
    return this;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    try {
      final storage = Get.find<StorageService>();
      String val = 'system';
      if (mode == ThemeMode.dark) val = 'dark';
      if (mode == ThemeMode.light) val = 'light';
      await storage.write(_storageKey, val);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  bool get isDarkMode {
    if (themeMode.value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return themeMode.value == ThemeMode.dark;
  }

  String get themeModeName {
    switch (themeMode.value) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }
}
