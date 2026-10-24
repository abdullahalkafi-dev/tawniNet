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
import 'app/services/deep_link_service.dart';
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

  // Storage (synchronous fast init)
  final storageService = await StorageService().init();
  Get.put(storageService, permanent: true);

  // API client
  final apiClient = ApiClient(storageService);
  Get.put(apiClient, permanent: true);

  // Synchronously register all GetX services so dependency injection is 100% available
  final roleService = RoleService();
  Get.put(roleService, permanent: true);
  try {
    await roleService.loadPersistedRole().timeout(const Duration(milliseconds: 300));
  } catch (_) {}

  final themeService = ThemeService();
  try {
    await themeService.init().timeout(const Duration(milliseconds: 300));
  } catch (_) {}
  Get.put(themeService, permanent: true);

  final localeService = LocaleService();
  try {
    await localeService.init().timeout(const Duration(milliseconds: 300));
  } catch (_) {}
  Get.put(localeService, permanent: true);

  final locationService = LocationService();
  Get.put(locationService, permanent: true);

  Get.put(RefetchService(), permanent: true);
  Get.put(SocketService(), permanent: true);
  Get.put(CategoryService(), permanent: true);
  Get.put(JobService(), permanent: true);
  Get.put(WalletService(), permanent: true);

  final supportService = SupportService();
  Get.put(supportService, permanent: true);
  Get.put(ReviewService(), permanent: true);

  final authService = AuthService();
  Get.put(authService, permanent: true);

  final notificationService = NotificationService();
  Get.put(notificationService, permanent: true);
  Get.put(NotificationApi(), permanent: true);

  final badge = NotificationBadgeController();
  Get.put(badge, permanent: true);

  Get.put(MessagesController(), permanent: true);
  Get.put(DeepLinkService(), permanent: true);

  // Render UI IMMEDIATELY: SplashView appears on screen in ~100ms
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
        supportedLocales: LocaleService.supportedLocales,
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

  // Non-blocking deferred startup: runs AFTER the first frame is rendered on screen.
  // Hardware sensors, GPS, FCM, network, and sockets will never freeze the UI.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // 1. Auth service init (loads saved user credentials & connects socket)
    try {
      await authService.init().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[Startup] AuthService init skipped/failed: $e');
    }

    // 2. GPS / Location service (hardware GPS status check)
    try {
      await locationService.init().timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[Startup] LocationService init skipped/failed: $e');
    }

    // 3. Push notifications (Firebase & FCM)
    try {
      await notificationService.init().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[Startup] NotificationService init skipped/failed: $e');
    }

    // 4. Support and Badge controllers
    try {
      await supportService.init().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await badge.init().timeout(const Duration(seconds: 2));
    } catch (_) {}
  });
}
