import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';
import 'package:awnneaapp/app/data/models/auth_model.dart';
import 'package:awnneaapp/app/modules/home/controllers/home_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_home/controllers/helper_home_controller.dart';
import 'package:awnneaapp/app/modules/helper/helper_jobs/controllers/helper_jobs_controller.dart';
import 'package:awnneaapp/app/modules/profile/controllers/profile_controller.dart';
import 'package:awnneaapp/app/modules/booking/controllers/booking_controller.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/morocco_phone_helper.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';

class AuthService extends GetxService {
  late final ApiClient _api;
  late final StorageService _storage;
  late final RoleService _roleService;

  final currentUser = Rxn<AuthUser>();
  final isLoggedIn = false.obs;
  final isEmailVerified = false.obs;

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

    // Set auth failed callback
    _api.onAuthFailed = () => logout();

    return this;
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

  // ─── Legacy Email Register & Login Fallbacks ─────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final role = _roleService.role;
    final response = await _api.post(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      },
    );

    if (response.success) {
      return {
        'status': response.data?['status'] ?? 'unverified',
        'email': response.data?['email'] ?? email,
      };
    }

    throw Exception(response.message ?? 'Registration failed');
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final response = await _api.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'otp': otp},
    );

    if (response.success && response.data != null) {
      await _handleAuthResponse(response.data);
    } else {
      throw Exception(response.message ?? 'OTP verification failed');
    }
  }

  Future<void> resendOtp({required String email}) async {
    final response = await _api.post(
      ApiConstants.resendOtp,
      data: {'email': email},
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Failed to resend OTP');
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    if (response.success && response.data != null) {
      await _handleAuthResponse(response.data);
      return currentUser.value?.role ?? 'user';
    }

    throw Exception(response.message ?? 'Login failed');
  }

  Future<void> forgotPassword({required String email}) async {
    final response = await _api.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Failed to send reset OTP');
    }
  }

  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _api.post(
      ApiConstants.verifyResetOtp,
      data: {'email': email, 'otp': otp},
    );

    if (response.success && response.data != null) {
      return response.data['resetToken'] ?? '';
    }

    throw Exception(response.message ?? 'Reset OTP verification failed');
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _api.post(
      ApiConstants.resetPassword,
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Password reset failed');
    }
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
    }
  }

  // ─── Logout ─────────────────────────────────────────────

  Future<void> logout() async {
    // 1. Disconnect socket
    try {
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().disconnect();
      }
    } catch (_) {}

    // 2. Clear messages and refetch listeners
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

    // 3. Clear ProfileController data and delete instance
    try {
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().clear();
        Get.delete<ProfileController>(force: true);
      }
    } catch (_) {}

    // 4. Delete Helper-specific controllers
    try {
      if (Get.isRegistered<HelperHomeController>()) {
        Get.delete<HelperHomeController>(force: true);
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<HelperJobsController>()) {
        Get.delete<HelperJobsController>(force: true);
      }
    } catch (_) {}

    // 5. Delete Client-specific controllers
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<BookingController>()) {
        Get.delete<BookingController>(force: true);
      }
    } catch (_) {}

    // 6. Reset auth state
    currentUser.value = null;
    isLoggedIn.value = false;
    isEmailVerified.value = false;
    _roleService.clearRole();

    // 7. Clear user tokens & JSON without wiping language/theme settings
    await _storage.clearAuthData();

    // 8. Route to role selection cleanly
    Get.offAllNamed(Routes.roleSelection);
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

    // Connect socket after successful auth
    try {
      final socketService = Get.find<SocketService>();
      final token = await _storage.getAccessToken();
      if (token != null) {
        socketService.connect(token);
      }
    } catch (_) {}
  }
}
