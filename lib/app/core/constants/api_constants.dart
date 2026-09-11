class ApiConstants {
  ApiConstants._();

  // Base URL — Configurable via --dart-define=API_BASE_URL=... (default: 10.0.2.2 for Android emulator)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.200:5000/api/v1',
  );

  /// Extract host from baseUrl (e.g., '192.168.0.200')
  static String get serverHost {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.host.isNotEmpty ? uri.host : '192.168.0.200';
    } catch (_) {
      return '192.168.0.200';
    }
  }

  /// Centralized image URL resolver.
  /// Replaces 'localhost' or '127.0.0.1' in any URL with the current serverHost so that
  /// physical mobile devices on the local network can resolve images correctly.
  /// Also routes direct MinIO bucket URLs through the backend proxy.
  static String? resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();

    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    // If it's a MinIO bucket URL (e.g. http://localhost:9000/tarik-uploads/...), proxy it via backend
    if (trimmed.contains('/tarik-uploads/')) {
      final key = trimmed.split('/tarik-uploads/').last;
      return '$cleanBase/upload/files/$key';
    }

    // If it's an API proxy URL, ensure it points to the active host
    if (trimmed.contains('/upload/files/')) {
      final key = trimmed.split('/upload/files/').last;
      return '$cleanBase/upload/files/$key';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final host = serverHost;
      return trimmed
          .replaceAll('://localhost', '://$host')
          .replaceAll('://127.0.0.1', '://$host');
    }

    // If it's a relative path or raw MinIO key:
    final cleanKey = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '$cleanBase/upload/files/$cleanKey';
  }

  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  // ─── Auth ───────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google-login';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';

  // ─── Moroccan Phone & WhatsApp Auth ────────────────────
  static const String phoneRegister = '/auth/phone-register';
  static const String verifyPhoneOtp = '/auth/verify-phone-otp';
  static const String resendWhatsappOtp = '/auth/resend-whatsapp-otp';
  static const String phoneLogin = '/auth/phone-login';
  static const String forgotPasswordPhone = '/auth/forgot-password-phone';
  static const String verifyResetOtpPhone = '/auth/verify-reset-otp-phone';
  static const String resetPasswordPhone = '/auth/reset-password-phone';

  // ─── Didit Automated KYC ────────────────────────────────
  static const String diditSession = '/didit/session';
  static const String diditSync = '/didit/sync';

  // ─── User ───────────────────────────────────────────────
  static const String userMe = '/user/me';
  static const String userLocation = '/user/location';
  static const String helperApply = '/user/helper/apply';
  static const String helperAppeal = '/user/helper/appeal';
  static const String helperApplicationStatus = '/user/helper/application-status';
  static const String deviceToken = '/user/device-token';

  // ─── Categories ─────────────────────────────────────────
  static const String categories = '/categories';
  static const String categoriesAll = '/categories/all';

  // ─── Upload ─────────────────────────────────────────────
  static const String uploadImage = '/upload/image';
  static const String uploadVideo = '/upload/video';
  static const String uploadDocument = '/upload/document';

  // ─── Geocoding ──────────────────────────────────────────
  static const String geocodingReverse = '/geocoding/reverse';
  static const String geocodingForward = '/geocoding/forward';

  // ─── Jobs ───────────────────────────────────────────────
  static const String jobs = '/jobs';
  static const String jobsNearby = '/jobs/nearby';
  static const String jobsMyBookings = '/jobs/my-bookings';
  static const String jobsMyAssigned = '/jobs/my-assigned-jobs';
  static String jobById(String id) => '/jobs/$id';
  static String acceptJob(String id) => '/jobs/$id/accept';
  static String completeJob(String id) => '/jobs/$id/complete';
  static String cancelJob(String id) => '/jobs/$id/cancel';
  static String jobCheckout(String id) => '/jobs/$id/checkout';

  // ─── Wallet & Payment ────────────────────────────────────
  static const String walletBalance = '/wallet/balance';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletTopup = '/wallet/topup';
  static const String paymentInitialize = '/payment/initialize';

  // ─── Notifications ──────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // ─── Support ─────────────────────────────────────────────
  static const String supportTickets = '/support/tickets';
  static String supportMessages(String ticketId) => '/support/tickets/$ticketId/messages';

  // ─── Reviews ─────────────────────────────────────────────
  static const String reviews = '/reviews';
  static String userReviews(String userId) => '/reviews/user/$userId';

  // ─── Helpers ────────────────────────────────────────────
  static const String helpersSearch = '/user/helpers/search';
  static String helperProfileById(String id) => '/user/helpers/$id';

  // ─── Chat ──────────────────────────────────────────────
  static const String chatConversations = '/chat/conversations';
  static String chatMessages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String chatOffer(String conversationId) =>
      '/chat/conversations/$conversationId/offer';
  static String chatOfferAccept(String conversationId, String offerId) =>
      '/chat/conversations/$conversationId/offer/$offerId/accept';
  static String chatOfferReject(String conversationId, String offerId) =>
      '/chat/conversations/$conversationId/offer/$offerId/reject';
  static String chatOfferCancel(String conversationId, String offerId) =>
      '/chat/conversations/$conversationId/offer/$offerId/cancel';
  static String chatOfferEdit(String conversationId, String offerId) =>
      '/chat/conversations/$conversationId/offer/$offerId/edit';
  static String chatMarkRead(String conversationId) =>
      '/chat/conversations/$conversationId/read';

  // ─── Admin ──────────────────────────────────────────────
  static const String adminStats = '/admin/stats';
  static const String adminHelpers = '/admin/helpers';
  static String adminApproveHelper(String userId) => '/admin/helpers/$userId/approve';
  static String adminRejectHelper(String userId) => '/admin/helpers/$userId/reject';
  static String adminBlockUser(String userId) => '/admin/users/$userId/block';
}
