import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, Icons, Icon, EdgeInsets;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/local_notification_helper.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/modules/booking/controllers/booking_controller.dart';

/// Background handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM][bg] ${message.messageId} data=${message.data}');
  try {
    // Isolate-safe: init Firebase + local notifications.
    // If the message has an FCM notification payload, the OS displays the banner automatically.
    // Only show local notification if it's a data-only payload to avoid duplicate banners.
    await Firebase.initializeApp();
    if (message.notification == null) {
      await LocalNotificationHelper.init();
      await LocalNotificationHelper.showFromRemoteMessage(message);
    }
  } catch (e) {
    debugPrint('[FCM][bg] local notification failed: $e');
  }
}

class NotificationService extends GetxService {
  /// Lazy — must NOT touch FirebaseMessaging.instance before InitializeApp.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  String? _fcmToken;
  String? _lastRegisteredToken;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  RemoteMessage? _pendingInitialMessage;
  bool _initialHandled = false;
  int _initialAttempts = 0;
  DateTime? _lastNavAt;
  String? _lastNavKey;
  final Map<String, RemoteMessage> _messagesByPayload = {};

  /// True when a notification is handling the initial cold-start navigation.
  /// SplashController checks this to yield navigation instead of overriding it.
  bool isColdStartHandling = false;

  String? get fcmToken => _fcmToken;

  String get _platform {
    if (kIsWeb) return 'android';
    try {
      return Platform.isIOS ? 'ios' : 'android';
    } catch (_) {
      return 'android';
    }
  }

  /// Ensure Firebase app exists. Safe to call many times.
  static Future<bool> ensureFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;
      await Firebase.initializeApp();
      debugPrint('[FCM] Firebase.initializeApp OK');
      return true;
    } catch (e) {
      debugPrint('[FCM] Firebase.initializeApp failed: $e');
      return false;
    }
  }

  Future<NotificationService> init() async {
    final ok = await ensureFirebase();
    if (!ok) return this;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('[FCM] onBackgroundMessage register failed: $e');
    }

    try {
      await LocalNotificationHelper.init(
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );
    } catch (e) {
      debugPrint('[FCM] LocalNotificationHelper init failed: $e');
    }

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[FCM] permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('[FCM] requestPermission failed: $e');
    }

    try {
      // Foreground: do NOT show OS/FCM banner — app draws its own snackbar only.
      // Background/killed still use the FCM notification payload (OS tray).
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (_) {}

    try {
      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    } catch (e) {
      debugPrint('[FCM] message listeners failed: $e');
    }

    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        isColdStartHandling = true;
        _pendingInitialMessage = initial;
        _scheduleInitialHandle();
      } else {
        final launchDetails = await LocalNotificationHelper.getLaunchDetails();
        if (launchDetails != null &&
            launchDetails.didNotificationLaunchApp &&
            launchDetails.notificationResponse?.payload != null) {
          final payload = launchDetails.notificationResponse!.payload!;
          final data = _decodePayload(payload);
          if (data.isNotEmpty) {
            isColdStartHandling = true;
            _scheduleInitialHandleData(data);
          }
        }
      }
    } catch (e) {
      debugPrint('[FCM] getInitialMessage failed: $e');
    }

    try {
      _onTokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _registerTokenIfLoggedIn(token);
      });

      _fcmToken = await _messaging.getToken();
      debugPrint('[FCM] token: ${_safeTokenPreview(_fcmToken)}');
      await _registerTokenIfLoggedIn(_fcmToken);
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
    }

    return this;
  }

  void _scheduleInitialHandle() {
    // Poll briefly until auth is ready; cold-start notification needs login first.
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (_initialHandled) return;
      final msg = _pendingInitialMessage;
      if (msg == null) return;

      final authReady = Get.isRegistered<AuthService>() &&
          Get.find<AuthService>().isLoggedIn.value;
      if (!authReady) {
        _initialAttempts++;
        if (_initialAttempts < 10) {
          _scheduleInitialHandle();
        } else {
          debugPrint('[FCM] initial message dropped — not logged in');
          _pendingInitialMessage = null;
        }
        return;
      }

      // Give the home shell a beat to mount before navigating.
      await Future.delayed(const Duration(milliseconds: 350));
      if (_initialHandled) return;
      _pendingInitialMessage = null;
      _initialHandled = true;
      _handleNotificationTap(msg);
      Future.delayed(const Duration(milliseconds: 1500), () {
        isColdStartHandling = false;
      });
    });
  }

  void _scheduleInitialHandleData(Map<String, String> data) {
    Future<void>.delayed(const Duration(milliseconds: 900), () async {
      if (_initialHandled) return;
      final authReady = Get.isRegistered<AuthService>() &&
          Get.find<AuthService>().isLoggedIn.value;
      if (!authReady) {
        _initialAttempts++;
        if (_initialAttempts < 10) {
          _scheduleInitialHandleData(data);
        } else {
          debugPrint('[FCM] initial local message dropped — not logged in');
          isColdStartHandling = false;
        }
        return;
      }
      await Future.delayed(const Duration(milliseconds: 350));
      if (_initialHandled) return;
      _initialHandled = true;
      navigateFromData(data);
      Future.delayed(const Duration(milliseconds: 1500), () {
        isColdStartHandling = false;
      });
    });
  }

  String _safeTokenPreview(String? token) {
    if (token == null || token.isEmpty) return 'none';
    return token.length <= 20 ? token : '${token.substring(0, 20)}...';
  }

  Future<void> _registerTokenIfLoggedIn(String? token) async {
    if (token == null || token.isEmpty) return;
    if (!Get.isRegistered<AuthService>()) return;

    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value) return;

    if (_lastRegisteredToken == token) return;

    try {
      final api = Get.find<ApiClient>();
      await api.post(
        ApiConstants.deviceToken,
        data: {'token': token, 'platform': _platform},
      );
      _lastRegisteredToken = token;
      debugPrint('[FCM] device token registered with backend');
    } catch (e) {
      debugPrint('[FCM] failed to register device token: $e');
    }
  }

  Future<void> registerWithBackend() async {
    try {
      debugPrint('[FCM] registerWithBackend start');
      final ok = await ensureFirebase();
      if (!ok) {
        debugPrint('[FCM] Firebase not ready — cannot register token');
        return;
      }
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        try {
          _fcmToken = await _messaging.getToken();
          debugPrint('[FCM] getToken → ${_safeTokenPreview(_fcmToken)}');
        } catch (e) {
          debugPrint('[FCM] getToken threw: $e');
          return;
        }
      } else {
        debugPrint('[FCM] using cached token ${_safeTokenPreview(_fcmToken)}');
      }
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        debugPrint('[FCM] no token available — skip register');
        return;
      }
      if (!Get.isRegistered<AuthService>()) {
        debugPrint('[FCM] AuthService missing — skip register');
        return;
      }
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value) {
        debugPrint('[FCM] not logged in yet — skip register');
        return;
      }
      _lastRegisteredToken = null;
      await _registerTokenIfLoggedIn(_fcmToken);
    } catch (e) {
      debugPrint('[FCM] registerWithBackend error: $e');
    }
  }

  Future<void> clearOnBackend() async {
    try {
      final api = Get.find<ApiClient>();
      await api
          .delete(ApiConstants.deviceToken)
          .timeout(const Duration(seconds: 5));
      _lastRegisteredToken = null;
    } catch (e) {
      debugPrint('[FCM] clear device token failed: $e');
      _lastRegisteredToken = null;
    }
  }

  /// Clear per-session notification memory on logout (payload map + debounce).
  void clearSessionState() {
    _messagesByPayload.clear();
    _pendingInitialMessage = null;
    _initialHandled = false;
    _initialAttempts = 0;
    _lastNavAt = null;
    _lastNavKey = null;
    _lastRegisteredToken = null;
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    debugPrint('[FCM][fg] title=${notification?.title} data=$data');

    final payload = LocalNotificationHelper.encodePayload(data);
    if (payload.isNotEmpty) {
      _messagesByPayload[payload] = message;
    }

    // App is open → in-app snackbar only.
    // Do not post a local/OS notification here (avoids double UI with FCM).
    final title = notification?.title ?? data['title'] as String?;
    final body = notification?.body ?? data['body'] as String?;
    if (title == null && body == null) return;

    try {
      Get.snackbar(
        title ?? 'Notification',
        body ?? '',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        backgroundColor: const Color(0xFFE6F7F5),
        colorText: const Color(0xFF0F766E),
        borderColor: const Color(0xFF5EC4B6),
        borderWidth: 1,
        icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0D9488)),
        onTap: (_) => _handleNotificationTap(message),
      );
    } catch (e) {
      debugPrint('[FCM] snackbar failed: $e');
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] opened from tray type=${message.data['type']}');
    _handleNotificationTap(message);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('[FCM] local notif tapped payload=${response.payload}');
    final encoded = response.payload;
    if (encoded != null && encoded.isNotEmpty) {
      // Prefer the exact message that produced this tray entry.
      final matched = _messagesByPayload[encoded];
      if (matched != null) {
        _handleNotificationTap(matched);
        return;
      }
      final data = _decodePayload(encoded);
      if (data.isNotEmpty) {
        _navigateFromData(data);
        return;
      }
    }
  }

  Map<String, String> _decodePayload(String encoded) {
    final data = <String, String>{};
    for (final pair in encoded.split('&')) {
      final i = pair.indexOf('=');
      if (i <= 0) continue;
      try {
        data[pair.substring(0, i)] = Uri.decodeComponent(pair.substring(i + 1));
      } catch (_) {
        data[pair.substring(0, i)] = pair.substring(i + 1);
      }
    }
    return data;
  }

  void _handleNotificationTap(RemoteMessage message) {
    final payload = LocalNotificationHelper.encodePayload(message.data);
    if (payload.isNotEmpty) {
      _messagesByPayload[payload] = message;
    }
    navigateFromData(Map<String, String>.from(message.data));
  }

  /// Public so in-app notification list can reuse the same deep-link rules.
  void navigateFromData(Map<String, dynamic> data) {
    _navigateFromData(data);
  }

  bool get _isHelperRole {
    if (Get.isRegistered<AuthService>()) {
      final user = Get.find<AuthService>().currentUser.value;
      if (user != null && user.role.toLowerCase() == 'helper') return true;
    }
    if (Get.isRegistered<RoleService>()) {
      return Get.find<RoleService>().isHelper;
    }
    return false;
  }

  void _goHome() {
    Get.toNamed(_isHelperRole ? Routes.helperHome : Routes.home);
  }

  /// Open helper jobs tab and auto-open a specific job if present in lists.
  void _openHelperJob(String? jobId) {
    if (Get.isRegistered<HelperJobsController>() && Get.isRegistered<HelperHomeController>()) {
      Get.find<HelperHomeController>().changeIndex(1);
      if (jobId != null && jobId.isNotEmpty) {
        Get.find<HelperJobsController>().setPendingOpenJobId(jobId);
      }
      if (Get.currentRoute != Routes.helperHome) {
        Get.toNamed(Routes.helperHome);
      }
      return;
    }
    Get.toNamed(
      Routes.helperHome,
      arguments: {
        'tab': 1,
        if (jobId != null && jobId.isNotEmpty) 'openJobId': jobId,
      },
    );
  }

  void _openClientJob(String? jobId) {
    if (jobId != null && jobId.isNotEmpty) {
      if (Get.isRegistered<BookingController>()) {
        Get.find<BookingController>().setPendingOpenJobId(jobId);
      }
      Get.toNamed(Routes.booking, arguments: {'jobId': jobId, 'id': jobId});
    } else {
      Get.toNamed(Routes.booking);
    }
  }

  void _openChat(String? conversationId) {
    if (conversationId == null || conversationId.isEmpty) {
      _goHome();
      return;
    }
    Get.toNamed(
      _isHelperRole ? Routes.helperChatDetail : Routes.chatDetail,
      arguments: conversationId,
    );
  }

  void _navigateFromData(Map<String, dynamic> data) {
    try {
      if (!Get.isRegistered<AuthService>()) return;
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value) return;

      final type = (data['type'] ?? '').toString();
      final isHelper = _isHelperRole;

      final conversationId = data['conversationId']?.toString();
      final ticketId = data['ticketId']?.toString();
      final jobId = data['jobId']?.toString();
      final orderId = data['orderId']?.toString();
      final orderType = data['orderType']?.toString() ?? '';

      // Debounce: system tray + local notification can double-fire the same tap.
      final navKey = '$type|$conversationId|$ticketId|$jobId|$orderId|$orderType';
      final now = DateTime.now();
      if (_lastNavKey == navKey &&
          _lastNavAt != null &&
          now.difference(_lastNavAt!) < const Duration(milliseconds: 900)) {
        debugPrint('[FCM] skip duplicate nav $navKey');
        return;
      }
      _lastNavKey = navKey;
      _lastNavAt = now;

      debugPrint('[FCM] navigate type=$type orderType=$orderType helper=$isHelper');

      switch (type) {
        case 'support_reply':
          if (ticketId != null && ticketId.isNotEmpty) {
            Get.toNamed(
              Routes.supportTicketList,
              arguments: {'ticketId': ticketId},
            );
          } else {
            Get.toNamed(Routes.supportTicketList);
          }
          break;

        case 'chat_message':
        case 'chat_offer':
        case 'offer_rejected':
        case 'offer_cancelled':
          _openChat(conversationId);
          break;

        case 'offer_accepted':
          // Chat path has conversationId; payment webhook path has jobId only.
          if (conversationId != null && conversationId.isNotEmpty) {
            _openChat(conversationId);
          } else if (isHelper) {
            _openHelperJob(jobId ?? orderId);
          } else {
            _openClientJob(jobId);
          }
          break;

        case 'payment_success':
          if (orderType == 'wallet_topup') {
            if (isHelper) {
              Get.toNamed(Routes.helperConnects);
            } else {
              Get.toNamed(Routes.wallet);
            }
          } else if (orderType == 'job') {
            if (isHelper) {
              _openHelperJob(orderId ?? jobId);
            } else {
              _openClientJob(orderId ?? jobId);
            }
          } else if (orderType == 'offer') {
            // orderId here is the offer message id — open job list, not chat.
            if (isHelper) {
              _openHelperJob(jobId);
            } else {
              Get.toNamed(Routes.booking);
            }
          } else if (orderType == 'commission' || orderType == 'commission_refund') {
            if (isHelper) {
              Get.toNamed(Routes.helperEarning);
            } else {
              _goHome();
            }
          } else {
            if (isHelper) {
              Get.toNamed(Routes.helperConnects);
            } else {
              Get.toNamed(Routes.wallet);
            }
          }
          break;

        case 'wallet_topup':
          if (isHelper) {
            Get.toNamed(Routes.helperConnects);
          } else {
            Get.toNamed(Routes.wallet);
          }
          break;

        case 'payment_failed':
          if (orderType == 'wallet_topup') {
            if (isHelper) {
              Get.toNamed(Routes.helperConnects);
            } else {
              Get.toNamed(Routes.wallet);
            }
          } else {
            if (isHelper) {
              _openHelperJob(orderId ?? jobId);
            } else {
              _openClientJob(orderId ?? jobId);
            }
          }
          break;

        case 'cash_received':
          if (isHelper) {
            Get.toNamed(Routes.helperEarning);
          } else {
            _openClientJob(jobId ?? orderId);
          }
          break;

        case 'kyc_approved':
          if (Get.isRegistered<RoleService>()) {
            Get.find<RoleService>().setUserRole('helper');
          }
          if (Get.isRegistered<AuthService>()) {
            Get.find<AuthService>().getMe();
          }
          Get.toNamed(Routes.helperHome);
          break;
        case 'kyc_rejected':
          Get.toNamed(Routes.applicationRejected);
          break;
        case 'kyc_pending':
          Get.toNamed(Routes.applicationPending);
          break;

        case 'job_accepted':
        case 'job_completed':
        case 'job_cancelled':
        case 'new_job':
          final id = (jobId != null && jobId.isNotEmpty) ? jobId : orderId;
          if (isHelper) {
            _openHelperJob(id);
          } else {
            _openClientJob(id);
          }
          break;

        case 'review_received':
          if (isHelper) {
            Get.toNamed(Routes.helperPublicProfile);
          } else {
            Get.toNamed(Routes.home);
          }
          break;

        default:
          _goHome();
      }
    } catch (e) {
      debugPrint('[FCM] handle tap failed: $e');
    }
  }

  @override
  void onClose() {
    _onMessageSub?.cancel();
    _onTokenRefreshSub?.cancel();
    _messagesByPayload.clear();
    super.onClose();
  }
}
