# Project Structure - 3awniNet Flutter App

```
lib/
├── main.dart
└── app/
    ├── core/
    │   ├── theme/
    │   │   └── app_theme.dart
    │   ├── values/
    │   │   ├── app_colors.dart          # Color palette
    │   │   ├── app_styles.dart          # Typography styles
    │   │   └── app_assets.dart          # Asset paths
    │   └── widgets/
    │       ├── custom_button.dart       # Shared button widget
    │       └── custom_text_field.dart   # Shared text field widget
    ├── data/
    │   └── models/
    │       ├── home_models.dart         # Category, HelperJob, PopularService
    │       ├── booking_model.dart       # Booking, BookingStatus
    │       └── helper_models.dart       # [NEW] HelperJobApplication, HelperProfile, Earning, Connects, etc.
    ├── routes/
    │   ├── app_routes.dart              # Route path constants
    │   └── app_pages.dart               # GetPage route definitions
    └── modules/
        ├── splash/                      # Splash screen
        ├── onboarding/                  # Onboarding (3 pages)
        ├── auth/                        # Authentication
        │   ├── login/                   # Login screen
        │   ├── signup/                  # Signup screen
        │   ├── role_selection/          # Role selection (User/Helper)
        │   ├── forgot_password/         # Forgot password flow
        │   ├── otp/                     # OTP verification
        │   └── reset_password/          # Reset password
        ├── home/                        # USER home module (Home/Booking/Messages/Profile)
        ├── booking/                     # USER booking module
        ├── messages/                    # USER messages (shared with helper)
        ├── profile/                     # USER profile module
        ├── search/                      # Search screen
        ├── find_helper/                 # Find helper screen
        ├── post_job/                    # Post job screen
        ├── checkout/                    # Checkout screen
        ├── helper_profile/              # Helper public profile (user view)
        ├── category_details/            # Category details
        └── helper/                      # [NEW] Helper-specific modules
            ├── location/
            │   ├── bindings/
            │   │   └── location_binding.dart
            │   ├── controllers/
            │   │   └── location_controller.dart
            │   └── views/
            │       ├── location_allow_view.dart
            │       └── manual_location_view.dart
            ├── apply/
            │   ├── bindings/
            │   │   └── apply_helper_binding.dart
            │   ├── controllers/
            │   │   └── apply_helper_controller.dart
            │   └── views/
            │       ├── apply_helper_view.dart
            │       ├── application_pending_view.dart
            │       └── application_rejected_view.dart
            ├── helper_home/
            │   ├── bindings/
            │   │   └── helper_home_binding.dart
            │   ├── controllers/
            │   │   └── helper_home_controller.dart
            │   ├── views/
            │   │   ├── helper_home_view.dart          # Shell with bottom nav
            │   │   ├── tabs/
            │   │   │   ├── helper_home_tab_view.dart  # Available jobs list
            │   │   │   ├── helper_jobs_tab_view.dart  # My Jobs (Active/Completed/Cancelled)
            │   │   │   ├── helper_messages_tab_view.dart
            │   │   │   └── helper_profile_tab_view.dart
            │   │   └── widgets/
            │   │       ├── helper_home_header.dart
            │   │       └── helper_job_card.dart
            │   └── helper_job_details_view.dart
            ├── jobs/
            │   ├── bindings/
            │   │   └── helper_jobs_binding.dart
            │   ├── controllers/
            │   │   └── helper_jobs_controller.dart
            │   └── views/
            │       ├── active_job_details_view.dart
            │       ├── completed_job_details_view.dart
            │       ├── cancel_details_view.dart
            │       └── rate_client_view.dart
            ├── helper_messages/
            │   └── views/
            │       └── helper_chat_detail_view.dart
            ├── profile/
            │   ├── bindings/
            │   │   └── helper_profile_binding.dart
            │   ├── controllers/
            │   │   └── helper_profile_controller.dart
            │   └── views/
            │       ├── helper_edit_profile_view.dart
            │       ├── helper_public_profile_view.dart
            │       ├── earning_view.dart
            │       ├── earning_summary_view.dart
            │       ├── add_card_view.dart
            │       ├── connects_view.dart
            │       └── buy_connects_view.dart
            └── settings/
                ├── bindings/
                │   └── helper_settings_binding.dart
                ├── controllers/
                │   └── helper_settings_controller.dart
                └── views/
                    ├── helper_notification_view.dart
                    └── help_center_view.dart
```

## Files Count
- **Existing files**: ~81 Dart files
- **New files to create**: ~45 Dart files
- **Files to modify**: 5 (routes, role_selection, login, signup controllers)
- **Total after implementation**: ~126 Dart files
