import 'package:get/get.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/auth/role_selection/bindings/role_selection_binding.dart';
import '../modules/auth/role_selection/views/role_selection_view.dart';
import '../modules/auth/login/bindings/login_binding.dart';
import '../modules/auth/login/views/login_view.dart';
import '../modules/auth/signup/bindings/signup_binding.dart';
import '../modules/auth/signup/views/signup_view.dart';
import '../modules/auth/forgot_password/bindings/forgot_password_binding.dart';
import '../modules/auth/forgot_password/views/forgot_password_view.dart';
import '../modules/auth/otp/bindings/otp_binding.dart';
import '../modules/auth/otp/views/otp_view.dart';
import '../modules/auth/reset_password/bindings/reset_password_binding.dart';
import '../modules/auth/reset_password/views/reset_password_view.dart';
import '../modules/search/bindings/search_binding.dart';
import '../modules/search/views/search_view.dart';
import '../modules/find_helper/bindings/find_helper_binding.dart';
import '../modules/find_helper/views/find_helper_view.dart';
import '../modules/category_details/views/category_details_view.dart';
import '../modules/post_job/bindings/post_job_binding.dart';
import '../modules/post_job/views/post_job_view.dart';
import '../modules/checkout/bindings/checkout_binding.dart';
import '../modules/checkout/views/checkout_view.dart';
import '../modules/helper_profile/bindings/helper_profile_binding.dart';
import '../modules/helper_profile/views/helper_profile_view.dart';
import '../modules/booking/bindings/booking_binding.dart';
import '../modules/booking/views/booking_view.dart';
import '../modules/booking/views/booking_details_view.dart';
import '../modules/booking/views/cancel_details_view.dart';
import '../modules/messages/views/chat_detail_view.dart';
import '../modules/profile/views/edit_profile_view.dart';
import '../modules/profile/views/notification_settings_view.dart';
import '../modules/wallet/views/wallet_view.dart';

// Helper module imports
import '../modules/helper/location/bindings/location_binding.dart';
import '../modules/helper/location/views/location_allow_view.dart';
import '../modules/helper/location/views/manual_location_view.dart';
import '../modules/helper/apply/bindings/apply_helper_binding.dart';
import '../modules/helper/apply/views/apply_helper_view.dart';
import '../modules/helper/apply/views/helper_kyc_view.dart';
import '../modules/helper/apply/views/application_pending_view.dart';
import '../modules/helper/apply/views/application_rejected_view.dart';
import '../modules/helper/helper_home/bindings/helper_home_binding.dart';
import '../modules/helper/helper_home/views/helper_home_view.dart';
import '../modules/helper/helper_home/views/helper_job_details_view.dart';
import '../modules/helper/helper_jobs/bindings/helper_jobs_binding.dart';
import '../modules/helper/helper_jobs/views/active_job_details_view.dart';
import '../modules/helper/helper_jobs/views/completed_job_details_view.dart';
import '../modules/helper/helper_jobs/views/cancel_details_view.dart' as helper_cancel;
import '../modules/helper/helper_jobs/views/rate_client_view.dart';
import '../modules/helper/profile/bindings/helper_profile_binding.dart' as helper_profile;
import '../modules/helper/profile/views/helper_edit_profile_view.dart';
import '../modules/helper/profile/views/helper_public_profile_view.dart';
import '../modules/helper/profile/views/earning_view.dart';
import '../modules/helper/profile/views/earning_summary_view.dart';
import '../modules/helper/profile/views/add_card_view.dart';
import '../modules/helper/profile/views/connects_view.dart';
import '../modules/helper/profile/views/buy_connects_view.dart';
import '../modules/helper/profile/views/connects_history_view.dart';
import '../modules/helper/settings/bindings/helper_settings_binding.dart';
import '../modules/helper/settings/views/helper_notification_view.dart';
import '../modules/helper/settings/views/helper_notification_settings_view.dart';
import '../modules/helper/settings/views/help_center_view.dart';
import '../modules/helper/settings/views/privacy_policy_view.dart';
import '../modules/helper/settings/views/about_us_view.dart';
import '../modules/helper/settings/views/customer_service_view.dart';
import '../modules/helper/settings/views/support_ticket_list_view.dart';
import '../modules/home/views/user_customer_service_view.dart';
import '../modules/helper/helper_messages/bindings/helper_messages_binding.dart';
import '../modules/helper/helper_messages/views/helper_chat_detail_view.dart';

import 'app_routes.dart';
import '../middlewares/auth_middleware.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.roleSelection,
      page: () => const RoleSelectionView(),
      binding: RoleSelectionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.signup,
      page: () => const SignupView(),
      binding: SignupBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.otpVerification,
      page: () => const OtpView(),
      binding: OtpBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.home,
      page: () => HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchView(),
      binding: SearchBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.findHelper,
      page: () => const FindHelperView(),
      binding: FindHelperBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.categoryDetails,
      page: () => const CategoryDetailsView(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.postJob,
      page: () => const PostJobView(),
      binding: PostJobBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.checkout,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperProfile,
      page: () => const HelperProfileView(),
      binding: HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.booking,
      page: () => const BookingView(),
      binding: BookingBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.bookingDetails,
      page: () => const BookingDetailsView(),
      binding: BookingBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.cancelDetails,
      page: () => const CancelDetailsView(),
      binding: BookingBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.chatDetail,
      page: () => const ChatDetailView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.notificationSettings,
      page: () => const NotificationSettingsView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),

    // Helper routes
    GetPage(
      name: Routes.locationAllow,
      page: () => const LocationAllowView(),
      binding: LocationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.manualLocation,
      page: () => const ManualLocationView(),
      binding: LocationBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.applyAsHelper,
      page: () => const ApplyHelperView(),
      binding: ApplyHelperBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.helperKycVerification,
      page: () => const HelperKycView(),
      binding: ApplyHelperBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.applicationPending,
      page: () => const ApplicationPendingView(),
      binding: ApplyHelperBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.applicationRejected,
      page: () => const ApplicationRejectedView(),
      binding: ApplyHelperBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.helperHome,
      page: () => HelperHomeView(),
      binding: HelperHomeBinding(),
      transition: Transition.fadeIn,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperJobDetails,
      page: () => const HelperJobDetailsView(),
      binding: HelperHomeBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.activeJobDetails,
      page: () => const ActiveJobDetailsView(),
      binding: HelperJobsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.completedJobDetails,
      page: () => const CompletedJobDetailsView(),
      binding: HelperJobsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperCancelDetails,
      page: () => const helper_cancel.HelperCancelDetailsView(),
      binding: HelperJobsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.rateClient,
      page: () => const RateClientView(),
      binding: HelperJobsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperEditProfile,
      page: () => const HelperEditProfileView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperPublicProfile,
      page: () => const HelperPublicProfileView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperEarning,
      page: () => const EarningView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperEarningSummary,
      page: () => const EarningSummaryView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.addCard,
      page: () => const AddCardView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperConnects,
      page: () => const ConnectsView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.buyConnects,
      page: () => const BuyConnectsView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.connectsHistory,
      page: () => const ConnectsHistoryView(),
      binding: helper_profile.HelperProfileBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperNotifications,
      page: () => const HelperNotificationView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperNotificationSettings,
      page: () => const HelperNotificationSettingsView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helpCenter,
      page: () => const HelpCenterView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.privacyPolicy,
      page: () => const PrivacyPolicyView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.aboutUs,
      page: () => const AboutUsView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.customerService,
      page: () => const CustomerServiceView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.supportTicketList,
      page: () => const SupportTicketListView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.userCustomerService,
      page: () => const UserCustomerServiceView(),
      binding: HelperSettingsBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.helperChatDetail,
      page: () => const HelperChatDetailView(),
      binding: HelperMessagesBinding(),
      transition: Transition.rightToLeft,
      middlewares: [AuthMiddleware()],
    ),
  ];
}
