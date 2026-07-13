import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/services/role_service.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/data/models/auth_model.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
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

  // ─── Register ───────────────────────────────────────────

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

  // ─── Verify OTP ─────────────────────────────────────────

  Future<void> verifyOtp({required String email, required String otp}) async {
    final response = await _api.post(
      ApiConstants.verifyOtp,
      data: {
        'email': email,
        'otp': otp,
      },
    );

    if (response.success && response.data != null) {
      await _handleAuthResponse(response.data);
    } else {
      throw Exception(response.message ?? 'OTP verification failed');
    }
  }

  // ─── Resend OTP ─────────────────────────────────────────

  Future<void> resendOtp({required String email}) async {
    final response = await _api.post(
      ApiConstants.resendOtp,
      data: {'email': email},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to resend OTP');
    }
  }

  // ─── Login ──────────────────────────────────────────────

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      await _handleAuthResponse(response.data);
      return currentUser.value?.role ?? 'user';
    }

    throw Exception(response.message ?? 'Login failed');
  }

  // ─── Google Login ───────────────────────────────────────

  Future<String> googleLogin({
    required String email,
    required String name,
    required String googleId,
    String? avatar,
  }) async {
    final role = _roleService.role;
    final response = await _api.post(
      ApiConstants.googleLogin,
      data: {
        'email': email,
        'name': name,
        'googleId': googleId,
        if (avatar != null) 'avatar': avatar,
        'role': role,
      },
    );

    if (response.success && response.data != null) {
      await _handleAuthResponse(response.data);
      return currentUser.value?.role ?? 'user';
    }

    throw Exception(response.message ?? 'Google login failed');
  }

  // ─── Forgot Password ────────────────────────────────────

  Future<void> forgotPassword({required String email}) async {
    final response = await _api.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );

    if (!response.success) {
      throw Exception(response.message ?? 'Failed to send reset OTP');
    }
  }

  // ─── Verify Reset OTP ───────────────────────────────────

  Future<String> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _api.post(
      ApiConstants.verifyResetOtp,
      data: {
        'email': email,
        'otp': otp,
      },
    );

    if (response.success && response.data != null) {
      return response.data['resetToken'] ?? '';
    }

    throw Exception(response.message ?? 'Reset OTP verification failed');
  }

  // ─── Reset Password ─────────────────────────────────────

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _api.post(
      ApiConstants.resetPassword,
      data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
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
    // Disconnect socket first
    try {
      final socketService = Get.find<SocketService>();
      socketService.disconnect();
    } catch (_) {}

    currentUser.value = null;
    isLoggedIn.value = false;
    isEmailVerified.value = false;
    _roleService.clearRole();
    await _storage.clearAll();
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
