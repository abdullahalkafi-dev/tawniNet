import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/services/role_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(RoleService(), permanent: true);
  runApp(
    GetMaterialApp(
      title: "Awnnea App",
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
    ),
  );
}
