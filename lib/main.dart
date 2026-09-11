import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/widgets/app_pull_to_refresh.dart';
import 'app/core/localization/app_translations.dart';
import 'app/core/localization/locale_service.dart';
import 'app/routes/app_pages.dart';
import 'app/services/storage_service.dart';
import 'app/services/api_client.dart';
import 'app/services/auth_service.dart';
import 'app/services/refetch_service.dart';
import 'app/services/socket_service.dart';
import 'app/services/category_service.dart';
import 'app/services/role_service.dart';
import 'app/services/location_service.dart';
import 'app/services/job_service.dart';
import 'app/services/wallet_service.dart';
import 'app/services/theme_service.dart';
import 'app/services/support_service.dart';
import 'app/services/review_service.dart';
import 'app/services/notification_service.dart';
import 'app/services/notification_api.dart';
import 'app/services/notification_badge_controller.dart';
import 'app/modules/messages/controllers/messages_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler — logs errors to terminal
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('[FlutterError] ${details.exception}');
    debugPrint(details.stack.toString());
  };

  // Catch async errors that escape the framework
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    debugPrint(stack.toString());
    return true;
  };

  // Firebase MUST be ready before any FirebaseMessaging access
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      debugPrint('[FCM] Firebase.initializeApp OK (main)');
    }
  } catch (e) {
    debugPrint('[FCM] Firebase.initializeApp failed (main): $e');
  }

  // Initialize storage first (must be async)
  final storageService = await StorageService().init();
  Get.put(storageService, permanent: true);

  // API client
  Get.put(ApiClient(storageService), permanent: true);

  // Location service (depends on ApiClient)
  final locationService = LocationService();
  await locationService.init();
  Get.put(locationService, permanent: true);

  // Services
  Get.put(RoleService(), permanent: true);
  Get.put(RefetchService(), permanent: true);
  Get.put(SocketService(), permanent: true);
  Get.put(CategoryService(), permanent: true);
  Get.put(JobService(), permanent: true);
  Get.put(WalletService(), permanent: true);
  final supportService = SupportService();
  await supportService.init();
  Get.put(supportService, permanent: true);
  Get.put(ReviewService(), permanent: true);

  // Auth service (depends on storage, api, role)
  final authService = AuthService();
  await authService.init();
  Get.put(authService, permanent: true);

  // Push notifications (FCM) — always register service so login can upload token
  try {
    final notificationService = NotificationService();
    Get.put(notificationService, permanent: true);
    await notificationService.init();
  } catch (e) {
    debugPrint('[FCM] NotificationService init skipped: $e');
  }
  Get.put(NotificationApi(), permanent: true);
  final badge = NotificationBadgeController();
  Get.put(badge, permanent: true);
  await badge.init();

  // Messages controller (permanent — needs to stay alive for online status)
  Get.put(MessagesController(), permanent: true);

  // Locale service (depends on storage)
  final localeService = LocaleService();
  await localeService.init();
  Get.put(localeService, permanent: true);

  // Theme service (depends on storage)
  final themeService = ThemeService();
  await themeService.init();
  Get.put(themeService, permanent: true);

  // Load persisted role
  await Get.find<RoleService>().loadPersistedRole();

  runApp(
    Obx(
      () => GetMaterialApp(
        title: "Awnnea App",
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeService.themeMode.value,
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: localeService.currentLocale.value,
        fallbackLocale: const Locale('en', 'US'),
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ar', 'MA'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // Make pull-to-refresh work with touch + mouse (emulator/desktop)
        // and with short lists / TabBarView children.
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: const AppScrollBehavior(),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    ),
  );
}
