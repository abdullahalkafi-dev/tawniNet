import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:awnneaapp/app/modules/booking/controllers/booking_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';

class DeepLinkService extends GetxService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void onInit() {
    super.onInit();
    _initDeepLinks();
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initDeepLinks() async {
    // 1. Cold start: Check if app was launched via a deep link (killed state)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DeepLink] Initial cold-start URI: $initialUri');
        handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLink] Error getting initial link: $e');
    }

    // 2. Warm start / Resumed: Listen to incoming deep links while running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('[DeepLink] Incoming stream URI: $uri');
        handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DeepLink] uriLinkStream error: $err');
      },
    );
  }

  bool handleUriString(String rawUri) {
    debugPrint('[DeepLink] Incoming rawUri string: $rawUri');
    try {
      final uri = Uri.parse(rawUri);
      return handleUri(uri);
    } catch (e) {
      debugPrint('[DeepLink] Failed to parse URI: $e');
      return false;
    }
  }

  bool handleUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    // 1. Didit verification callback: tarik://didit/callback, /didit/callback, or webhooks/didit
    if (host == 'didit' || path.contains('didit') || path.contains('webhooks/didit')) {
      _handleDiditCallback(uri);
      return true;
    }

    // 2. Payment callback: tarik://payment/callback or /payment/callback
    if (host == 'payment' || path.contains('payment/callback')) {
      _handlePaymentCallback(uri);
      return true;
    }

    return false;
  }

  void _handleDiditCallback(Uri uri) async {
    final sessionId = uri.queryParameters['sessionId'] ?? uri.queryParameters['session_id'];
    final status = (uri.queryParameters['status'] ?? '').toLowerCase();
    debugPrint('[DeepLink] Didit callback sessionId=$sessionId status=$status');

    if (!Get.isRegistered<AuthService>()) return;
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) return;

    // Give UI a moment to be active
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        await authService.syncDiditSession(sessionId);
      }
      await authService.getMe();
      final user = authService.currentUser.value;

      if (user?.helperApplicationStatus == 'approved' || status == 'approved') {
        if (Get.isRegistered<RoleService>()) {
          Get.find<RoleService>().setUserRole('helper');
        }
        AppFeedback.success('KYC verification approved! Welcome to Tarik.');
        Get.offAllNamed(Routes.helperHome);
      } else if (user?.helperApplicationStatus == 'rejected' || status == 'declined' || status == 'rejected') {
        AppFeedback.error(user?.rejectionReason ?? 'Verification was not approved');
        Get.offAllNamed(Routes.applicationRejected);
      } else if (user?.diditStatus == 'In Review' || user?.helperApplicationStatus == 'pending_appeal') {
        Get.offAllNamed(Routes.applicationPending);
      } else {
        AppFeedback.info('Verification in progress...');
        Get.toNamed(Routes.helperKycVerification);
      }
    } catch (e) {
      debugPrint('[DeepLink] Didit sync error: $e');
    }
  }

  void _handlePaymentCallback(Uri uri) async {
    final status = (uri.queryParameters['status'] ?? '').toLowerCase();
    final orderId = uri.queryParameters['orderId'] ?? uri.queryParameters['order_id'];
    final orderType = (uri.queryParameters['orderType'] ?? uri.queryParameters['order_type'] ?? '').toLowerCase();
    debugPrint('[DeepLink] Payment callback status=$status orderId=$orderId orderType=$orderType');

    // 1. Guard against unauthenticated cold starts
    if (!Get.isRegistered<AuthService>()) return;
    final authService = Get.find<AuthService>();
    if (!authService.isLoggedIn.value) {
      debugPrint('[DeepLink] Payment callback ignored — user not authenticated');
      Get.offAllNamed(Routes.login);
      return;
    }

    // 2. Ensure user profile and role are populated (especially on cold start)
    if (authService.currentUser.value == null) {
      try {
        await authService.getMe();
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final isHelper = Get.isRegistered<RoleService>() && Get.find<RoleService>().isHelper;

    // If Checkout sheet/modal is open, dismiss it first
    if (Get.currentRoute == Routes.checkout) {
      Get.back(result: status == 'success');
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (status == 'success') {
      AppFeedback.success('Payment completed successfully!');
      if (orderType == 'wallet_topup') {
        if (isHelper) {
          if (Get.currentRoute != Routes.helperConnects) {
            Get.toNamed(Routes.helperConnects);
          }
        } else {
          if (Get.currentRoute != Routes.wallet) {
            Get.toNamed(Routes.wallet);
          }
        }
      } else {
        if (isHelper) {
          if (Get.isRegistered<HelperHomeController>()) {
            Get.find<HelperHomeController>().changeIndex(1);
            if (orderId != null && orderId.isNotEmpty && Get.isRegistered<HelperJobsController>()) {
              Get.find<HelperJobsController>().setPendingOpenJobId(orderId);
            }
            Get.until((route) => route.settings.name == Routes.helperHome || route.isFirst);
          } else {
            Get.offAllNamed(
              Routes.helperHome,
              arguments: {
                'tab': 1,
                'openJobId': ?orderId,
              },
            );
          }
        } else {
          if (orderId != null && orderId.isNotEmpty && Get.isRegistered<BookingController>()) {
            Get.find<BookingController>().setPendingOpenJobId(orderId);
          }
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().changeIndex(1);
            Get.until((route) => route.settings.name == Routes.home || route.isFirst);
          } else {
            Get.offAllNamed(
              Routes.home,
              arguments: {
                'tab': 1,
                'jobId': ?orderId,
              },
            );
          }
        }
      }
    } else {
      AppFeedback.error('Payment was cancelled or failed.');
      if (orderType == 'wallet_topup') {
        if (isHelper) {
          if (Get.currentRoute != Routes.helperConnects) {
            Get.toNamed(Routes.helperConnects);
          }
        } else {
          if (Get.currentRoute != Routes.wallet) {
            Get.toNamed(Routes.wallet);
          }
        }
      } else {
        if (isHelper) {
          if (Get.isRegistered<HelperHomeController>()) {
            Get.find<HelperHomeController>().changeIndex(1);
            Get.until((route) => route.settings.name == Routes.helperHome || route.isFirst);
          } else {
            Get.offAllNamed(Routes.helperHome, arguments: {'tab': 1});
          }
        } else {
          if (Get.isRegistered<HomeController>()) {
            Get.find<HomeController>().changeIndex(1);
            Get.until((route) => route.settings.name == Routes.home || route.isFirst);
          } else {
            Get.offAllNamed(Routes.home, arguments: {'tab': 1});
          }
        }
      }
    }
  }
}
