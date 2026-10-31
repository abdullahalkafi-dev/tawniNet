import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/widgets/app_dialogs.dart';
import 'package:awnneaapp/app/services/app_config_service.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/services/notification_service.dart';
import 'package:awnneaapp/app/services/notification_badge_controller.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/data/models/auth_model.dart';
import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:awnneaapp/app/modules/helper/settings/controllers/customer_service_controller.dart';
import 'package:awnneaapp/app/modules/profile/controllers/profile_controller.dart';
import 'package:awnneaapp/app/modules/booking/controllers/booking_controller.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/morocco_phone_helper.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';

/// Minimum password length (the server enforces the same rule).
const int kMinPasswordLength = 8;

/// Storage key: the Terms version accepted at sign-up, recorded at the first login.
const String kPendingLegalKey = 'pending_legal_version';

class AuthService extends GetxService {
  late final ApiClient _api;
  late final StorageService _storage;
  late final RoleService _roleService;

  final currentUser = Rxn<AuthUser>();
  final isLoggedIn = false.obs;
  final isEmailVerified = false.obs;

  /// Completes when the saved session has been loaded (the splash waits for it).
  final Completer<void> ready = Completer<void>();

  /// Where the signed-in user belongs: client home, or the helper's current
  /// step (application form → ID check → pending/rejected → helper home).
  /// A saved location is NOT required: it is asked for when it is needed.
  String destinationFor(AuthUser? user) {
    if (user == null) return Routes.roleSelection;
    if (user.role != 'helper') return Routes.home;
    if (!user.isHelperFormSubmitted) return Routes.applyAsHelper;
    switch (user.helperApplicationStatus) {
      case 'approved':
        return Routes.helperHome;
      case 'pending_appeal':
        return Routes.applicationPending;
      case 'rejected':
        return Routes.applicationRejected;
      case 'pending':
      default:
        return user.diditStatus == 'In Review'
            ? Routes.applicationPending
            : Routes.helperKycVerification;
    }
  }

  /// Open the right screen for the current user (after login / signup / splash).
  void goToDestination() => Get.offAllNamed(destinationFor(currentUser.value));

  // ─── Init ───────────────────────────────────────────────

  Future<AuthService> init() async {
    _api = Get.find<ApiClient>();
    _storage = Get.find<StorageService>();
    _roleService = Get.find<RoleService>();
    // Load stored user and tokens on startup
    final hasTokens = await _storage.hasTokens();
    if (hasTokens) {
      final userJson = await _storage.getUserJson();
      if (userJson != null) {
        currentUser.value = AuthUser.fromJson(userJson);
        final role = await _storage.getRole();
        if (role != null && role.isNotEmpty) {
          _roleService.setUserRole(role);
        }
        isLoggedIn.value = true;
        isEmailVerified.value = currentUser.value?.status == 'active';

        // Connect socket if user is already logged in
        try {
          final socketService = Get.find<SocketService>();
          final token = await _storage.getAccessToken();
          if (token != null) {
            socketService.connect(token);
          }
        } catch (_) {}
      }
    }

    if (!ready.isCompleted) ready.complete();

    // The session is definitively over (server refused the refresh token).
    _api.onAuthFailed = () => logout(notifyServer: false);
    // Keep the live connection on the newest token.
    _api.onTokenRefreshed = (token) {
      try {
        Get.find<SocketService>().updateToken(token);
      } catch (_) {}
    };

    return this;
  }

  /// Refresh the saved profile from the server before the app routes anywhere,
  /// so a user who was blocked / rejected / approved meanwhile sees the truth.
  /// Network trouble keeps the cached profile; a refused session logs out once.
  Future<void> refreshSession({Duration timeout = const Duration(seconds: 5)}) async {
    if (!isLoggedIn.value) return;
    try {
      await getMe().timeout(timeout);
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] profile refresh skipped: $e');
    }
  }

  // ─── Phone Registration (Morocco WhatsApp OTP) ─────────

  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String password,
    required String name,
  }) async {
    final normalizedPhone = MoroccoPhoneHelper.normalize(phone);
    final role = _roleService.role;
    final response = await _api.post(
      ApiConstants.phoneRegister,
      data: {
        'phone': normalizedPhone,
        'password': password,
        'name': name,
        'role': role,
      },
    );

    if (response.success) {
      return {
        'status': response.data?['status'] ?? 'unverified',
        'phone': response.data?['phone'] ?? normalizedPhone,
      };
    }

    throw Exception(response.message ?? 'Registration failed');
  }

  // ─── Verify Phone OTP (6 Digits) ────────────────────────

  Future<void> verifyPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    final normalizedPhone = MoroccoPhoneHelper.normalize(phone);
    final response = await _api.post(
      ApiConstants.verifyPhoneOtp,
      data: {
        'phone': normalizedPhone,
        'otp': otp,
      },
    );

    if (response.success && response.data != null) {
      await _handleAuthResponse(response.data);
    } else {
      throw Exception(response.message ?? 'WhatsApp OTP verification failed');
    }
  }

  // ─── Resend WhatsApp OTP ────────────────────────────────

  Future<void> resendPhoneOtp({required String phone}) async {
    final normalizedPhone = MoroccoPhoneHelper.normalize(phone);
    final response = await _api.post(
      ApiConstants.resendWhatsappOtp,
      data: {'phone': normalizedPhone},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to resend WhatsApp code');
    }
  }

  // ─── Phone Login (Daily Login) ──────────────────────────

  Future<String> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = MoroccoPhoneHelper.normalize(phone);
    final response = await _api.post(
      ApiConstants.phoneLogin,
      data: {
        'phone': normalizedPhone,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      // Check if unverified
      if (response.data['status'] == 'unverified' || response.data['isPhoneVerified'] == false) {
        return 'unverified';
      }
      await _handleAuthResponse(response.data);
      return currentUser.value?.role ?? 'user';
    }

    throw Exception(response.message ?? 'Login failed');
  }

  // ─── Forgot Password (Phone) ────────────────────────────

  Future<void> forgotPasswordPhone({required String phone}) async {
    final normalizedPhone = MoroccoPhoneHelper.normalize(phone);
    final response = await _api.post(
      ApiConstants.forgotPasswordPhone,
      data: {'phone': normalizedPhone},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to send WhatsApp reset code');
    }
  }

  // ─── Verify Reset OTP (Phone) ───────────────────────────

  Future<String> verifyResetOtpPhone({
    required String phone,
    required String otp,
  }) async {
    final normalizedPhone = MoroccoPhoneHelper.normalize(phone);
    final response = await _api.post(
      ApiConstants.verifyResetOtpPhone,
      data: {
        'phone': normalizedPhone,
        'otp': otp,
      },
    );

    if (response.success && response.data != null) {
      return response.data['resetToken'] ?? '';
    }

    throw Exception(response.message ?? 'Reset OTP verification failed');
  }

  // ─── Reset Password (Phone) ─────────────────────────────

  Future<void> resetPasswordPhone({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _api.post(
      ApiConstants.resetPasswordPhone,
      data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Password reset failed');
    }
  }

  // ─── Didit Automated KYC Integration ────────────────────

  Future<Map<String, dynamic>> createDiditSession() async {
    final response = await _api.post(ApiConstants.diditSession);
    if (response.success && response.data != null) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception(response.message ?? 'Failed to start KYC verification');
  }

  Future<Map<String, dynamic>> syncDiditSession(String sessionId) async {
    final response = await _api.post(
      ApiConstants.diditSync,
      data: {'sessionId': sessionId},
    );
    if (response.success && response.data != null) {
      await getMe(); // Refresh local profile
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception(response.message ?? 'Failed to sync verification decision');
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.patch(
      ApiConstants.userMe,
      data: data,
    );
    if (response.success) {
      await getMe();
      return;
    }
    throw Exception(response.message ?? 'Failed to update profile');
  }

  // ─── Submit Rejection Appeal ─────────────────────────────

  Future<void> submitAppeal(String message) async {
    final response = await _api.post(
      ApiConstants.helperAppeal,
      data: {'message': message},
    );
    if (response.success) {
      await getMe(); // Refresh local profile with pending_appeal
      return;
    }
    throw Exception(response.message ?? 'Failed to submit appeal');
  }

  // ─── Account actions ────────────────────────────────────

  /// Change the password. The server ends every other session and returns a
  /// fresh token pair for this device.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _api.post(
      ApiConstants.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      fromData: (d) => d,
    );
    final data = response.data;
    if (response.success && data is Map) {
      final access = data['accessToken']?.toString();
      final refresh = data['refreshToken']?.toString();
      if (access != null && refresh != null) {
        await _storage.saveTokens(accessToken: access, refreshToken: refresh);
        try {
          Get.find<SocketService>().updateToken(access);
        } catch (_) {}
      }
      return;
    }
    throw ApiException(response.message ?? 'err_http_unknown'.tr);
  }

  /// Delete (anonymise) the account. Needs the password; fails with a clear
  /// message while jobs are active or the wallet still holds money.
  Future<void> deleteAccount(String password) async {
    final response = await _api.delete(
      ApiConstants.userMe,
      data: {'password': password},
    );
    if (!response.success) {
      throw ApiException(response.message ?? 'err_http_unknown'.tr);
    }
    await logout(notifyServer: false);
  }

  /// Helper "available / off duty" switch.
  Future<void> setAvailability(bool available) async {
    final response = await _api.patch(
      ApiConstants.availability,
      data: {'isAvailable': available},
    );
    if (!response.success) {
      throw ApiException(response.message ?? 'err_http_unknown'.tr);
    }
    final user = currentUser.value;
    if (user != null) {
      currentUser.value = user.copyWithAvailability(available);
      await _storage.saveUserJson(currentUser.value!.toJson());
    }
  }

  /// Record that the user accepted the given Terms / Privacy version.
  Future<void> acceptLegal(int version) async {
    final response = await _api.post(ApiConstants.acceptLegal, data: {'version': version});
    if (!response.success) {
      throw ApiException(response.message ?? 'err_http_unknown'.tr);
    }
    await getMe();
  }

  /// Save notification switches (push / sound / vibrate / payments / appUpdates / newService).
  Future<void> saveNotificationPrefs(Map<String, bool> prefs) async {
    await _api.patch(ApiConstants.userMe, data: {'notificationPrefs': prefs});
    await getMe();
  }

  // ─── Get Me (fetch fresh profile) ───────────────────────

  Future<void> getMe() async {
    final response = await _api.get(
      ApiConstants.userMe,
      fromData: (data) => data,
    );

    if (response.success && response.data != null) {
      final userJson = Map<String, dynamic>.from(response.data);
      await _storage.saveUserJson(userJson);
      currentUser.value = AuthUser.fromJson(userJson);
      final role = currentUser.value?.role;
      if (role != null && role.isNotEmpty) {
        _roleService.setUserRole(role);
      }
    }
  }

  // ─── Logout ─────────────────────────────────────────────

  static bool _loggingOut = false;

  Future<void> logout({bool notifyServer = true}) async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await _performLogout(notifyServer: notifyServer);
    } finally {
      _loggingOut = false;
    }
  }

  /// End this device's session on the server (best effort, never blocks logout).
  Future<void> _endServerSession() async {
    try {
      final access = await _storage.getAccessToken();
      final refresh = await _storage.getRefreshToken();
      if (access == null || access.isEmpty) return;
      await dio.Dio(dio.BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      )).post(
        '${ApiConstants.baseUrl}${ApiConstants.logout}',
        data: {if (refresh != null) 'refreshToken': refresh},
        options: dio.Options(headers: {'Authorization': 'Bearer $access'}),
      );
    } catch (_) {}
  }

  Future<void> _performLogout({bool notifyServer = true}) async {
    if (notifyServer) {
      await _endServerSession();
    }
    // 0. Unregister FCM (best-effort, short timeout) — before clearing tokens
    try {
      if (Get.isRegistered<NotificationService>()) {
        await Get.find<NotificationService>()
            .clearOnBackend()
            .timeout(const Duration(seconds: 4));
        Get.find<NotificationService>().clearSessionState();
      }
    } catch (_) {}

    // 0b. Reset unread badge so the next login does not show the old count
    try {
      if (Get.isRegistered<NotificationBadgeController>()) {
        Get.find<NotificationBadgeController>().clear();
      }
    } catch (_) {}

    // 1. Leave support rooms / drop socket
    try {
      if (Get.isRegistered<CustomerServiceController>()) {
        Get.find<CustomerServiceController>().clearSelection();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().disconnect();
      }
    } catch (_) {}

    // 2. Clear in-memory session data WITHOUT deleting controllers
    //    that mounted views still depend on (HelperHomeView etc.).
    //    Deleting while the tree is dirty causes:
    //    "HelperHomeController" not found during Obx rebuild.
    try {
      if (Get.isRegistered<MessagesController>()) {
        Get.find<MessagesController>().clear();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<RefetchService>()) {
        Get.find<RefetchService>().clear();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clear();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<CustomerServiceController>()) {
        final c = Get.find<CustomerServiceController>();
        c.clearSelection();
        c.tickets.clear();
        c.messages.clear();
      }
    } catch (_) {}

    // 3. Reset auth flags + storage first so any late API is unauthorized safely
    currentUser.value = null;
    isLoggedIn.value = false;
    isEmailVerified.value = false;
    try {
      _roleService.clearRole();
    } catch (_) {}
    try {
      await _storage.clearAuthData();
    } catch (_) {}

    // 4. Leave authenticated stack FIRST (unmounts HelperHomeView, etc.)
    try {
      Get.offAllNamed(Routes.roleSelection);
    } catch (_) {
      try {
        Get.offAllNamed(Routes.login);
      } catch (_) {}
    }

    // 5. Tear down role-specific controllers AFTER the old routes are gone
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      void tryDelete<T>() {
        try {
          if (Get.isRegistered<T>()) {
            Get.delete<T>(force: true);
          }
        } catch (_) {}
      }

      tryDelete<ProfileController>();
      tryDelete<HelperHomeController>();
      tryDelete<HelperJobsController>();
      tryDelete<HomeController>();
      tryDelete<BookingController>();
    });
  }

  // ─── Terms of Service ───────────────────────────────────

  /// Sign-up accepted the Terms before the account existed: record it now.
  Future<void> _submitPendingLegal() async {
    try {
      final raw = await _storage.read(kPendingLegalKey);
      final version = int.tryParse(raw ?? '');
      if (version == null) return;
      await acceptLegal(version);
      await _storage.write(kPendingLegalKey, '');
    } catch (_) {
      // retried at the next login
    }
  }

  bool _legalPromptOpen = false;

  /// After the Terms changed (new version), ask the user once to accept them.
  Future<void> promptLegalIfNeeded() async {
    if (_legalPromptOpen || !isLoggedIn.value) return;
    final user = currentUser.value;
    if (user == null || !Get.isRegistered<AppConfigService>()) return;
    final config = Get.find<AppConfigService>();
    final current = config.legalVersion.value;
    final accepted = user.acceptedLegalVersion;
    // Existing accounts without a record are asked as well.
    if (accepted != null && accepted >= current) return;
    _legalPromptOpen = true;
    try {
      final ok = await AppDialogs.confirm(
        title: 'legal_update_title'.tr,
        message: 'legal_update_body'.tr,
        confirmLabel: 'legal_update_accept'.tr,
        cancelLabel: 'legal_update_read'.tr,
      );
      if (ok) {
        await acceptLegal(current);
      }
    } catch (_) {
    } finally {
      _legalPromptOpen = false;
    }
  }

  // ─── Internal Helpers ───────────────────────────────────

  Future<void> _handleAuthResponse(dynamic data) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final userData = data['user'] as Map<String, dynamic>?;

    if (accessToken != null && refreshToken != null) {
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    if (userData != null) {
      await _storage.saveUserJson(userData);
      currentUser.value = AuthUser.fromJson(userData);

      // Set role from backend response
      final role = userData['role'] as String? ?? 'user';
      _roleService.setUserRole(role);
      await _storage.saveRole(role);
    }

    isLoggedIn.value = true;
    isEmailVerified.value = currentUser.value?.status == 'active';

    unawaited(_submitPendingLegal());

    // Connect socket after successful auth
    try {
      final socketService = Get.find<SocketService>();
      final token = await _storage.getAccessToken();
      if (token != null) {
        socketService.connect(token);
      }
    } catch (_) {}

    // Register FCM device token for push notifications (user + helper)
    Future<void> tryRegisterFcm(String label) async {
      try {
        debugPrint('[FCM] $label — registering device token...');
        final ready = await NotificationService.ensureFirebase();
        if (!ready) {
          debugPrint('[FCM] $label — Firebase not ready');
          return;
        }
        if (!Get.isRegistered<NotificationService>()) {
          debugPrint('[FCM] NotificationService missing — creating + init');
          final ns = NotificationService();
          Get.put(ns, permanent: true);
          await ns.init();
        }
        await Get.find<NotificationService>().registerWithBackend();
        debugPrint('[FCM] $label — registerWithBackend finished');
      } catch (e) {
        debugPrint('[FCM] $label — register failed: $e');
      }
    }

    await tryRegisterFcm('login-immediate');
    // Retry shortly after — Firebase token can be ready a beat after first login frame
    Future<void>.delayed(const Duration(seconds: 2), () => tryRegisterFcm('login+2s'));
    Future<void>.delayed(const Duration(seconds: 6), () => tryRegisterFcm('login+6s'));
  }
}
