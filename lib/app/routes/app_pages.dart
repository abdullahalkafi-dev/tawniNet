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
import 'app_routes.dart';

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
    ),
    GetPage(
      name: Routes.search,
      page: () => const SearchView(),
      binding: SearchBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.findHelper,
      page: () => const FindHelperView(),
      binding: FindHelperBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.categoryDetails,
      page: () => const CategoryDetailsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.postJob,
      page: () => const PostJobView(),
      binding: PostJobBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.checkout,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.helperProfile,
      page: () => const HelperProfileView(),
      binding: HelperProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.booking,
      page: () => const BookingView(),
      binding: BookingBinding(),
    ),
    GetPage(
      name: Routes.bookingDetails,
      page: () => const BookingDetailsView(),
      binding: BookingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.cancelDetails,
      page: () => const CancelDetailsView(),
      binding: BookingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.chatDetail,
      page: () => const ChatDetailView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => const EditProfileView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.notificationSettings,
      page: () => const NotificationSettingsView(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
