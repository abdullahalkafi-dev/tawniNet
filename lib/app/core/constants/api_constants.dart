class ApiConstants {
  ApiConstants._();

  // Base URL — Real device on same WiFi
  static const String baseUrl = 'http://192.168.0.200:5000/api/v1';

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

  // ─── User ───────────────────────────────────────────────
  static const String userMe = '/user/me';
  static const String userLocation = '/user/location';
  static const String helperApply = '/user/helper/apply';
  static const String helperApplicationStatus = '/user/helper/application-status';

  // ─── Categories ─────────────────────────────────────────
  static const String categories = '/categories';
  static const String categoriesAll = '/categories/all';

  // ─── Upload ─────────────────────────────────────────────
  static const String uploadImage = '/upload/image';
  static const String uploadDocument = '/upload/document';

  // ─── Geocoding ──────────────────────────────────────────
  static const String geocodingReverse = '/geocoding/reverse';
  static const String geocodingForward = '/geocoding/forward';

  // ─── Jobs ───────────────────────────────────────────────
  static const String jobs = '/jobs';
  static const String jobsNearby = '/jobs/nearby';
  static String jobById(String id) => '/jobs/$id';

  // ─── Helpers ────────────────────────────────────────────
  static const String helpersSearch = '/user/helpers/search';

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
