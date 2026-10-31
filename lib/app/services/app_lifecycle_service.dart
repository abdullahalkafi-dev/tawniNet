import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/app_config_service.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/notification_badge_controller.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';

/// Keeps the app in sync after it comes back from the background:
/// reconnects the live connection and refetches the lists that may be stale.
class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  DateTime? _pausedAt;
  DateTime? _lastResync;

  /// Only resync if we were away at least this long (avoids a refetch storm
  /// when the user flips between apps quickly).
  static const _minAway = Duration(seconds: 20);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // A (re)connection means events may have been missed.
    ever(Get.find<AuthService>().isLoggedIn, (logged) {
      if (logged == true) _listenSocket();
    });
    if (Get.find<AuthService>().isLoggedIn.value) _listenSocket();
  }

  StreamSubscription<void>? _syncSub;

  void _listenSocket() {
    _syncSub?.cancel();
    _syncSub = Get.find<SocketService>().onSynced.listen((_) => resync(force: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (!Get.find<AuthService>().isLoggedIn.value) return;
      Get.find<SocketService>().ensureConnected();
      if (away >= _minAway) resync();
    }
  }

  /// Refetch everything that may have changed while we were not listening.
  Future<void> resync({bool force = false}) async {
    if (!Get.find<AuthService>().isLoggedIn.value) return;
    final now = DateTime.now();
    if (_lastResync != null && now.difference(_lastResync!).inSeconds < (force ? 3 : 10)) return;
    _lastResync = now;

    // Server settings (commission, minimums, legal version, minimum app version) and the
    // profile (blocked / approved / availability) can change while the app is in the background.
    unawaited(_refreshServerState());

    try {
      if (Get.isRegistered<MessagesController>()) {
        unawaited(Get.find<MessagesController>().fetchConversations());
      }
      if (Get.isRegistered<NotificationBadgeController>()) {
        unawaited(Get.find<NotificationBadgeController>().refresh());
      }
      await Get.find<RefetchService>().resyncAll();
    } catch (_) {}
  }

  Future<void> _refreshServerState() async {
    try {
      if (Get.isRegistered<AppConfigService>()) {
        final config = Get.find<AppConfigService>();
        await config.refresh();
        if (config.updateRequired && Get.currentRoute != Routes.updateRequired) {
          Get.offAllNamed(Routes.updateRequired);
          return;
        }
      }
      final auth = Get.find<AuthService>();
      await auth.getMe();
      await auth.promptLegalIfNeeded();
    } catch (_) {
      // best effort: the screens keep what they already show
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncSub?.cancel();
    super.onClose();
  }
}
