# AGENTS.md - Development Guidelines

## Architecture
- **Framework**: Flutter with GetX (v4.6.6)
- **Pattern**: Module-based MVC (GetView + GetxController + Bindings)
- **Routing**: GetX named routing with `GetPage` definitions
- **State**: Reactive `.obs` observables with `Obx(() => ...)` widgets

## Role System
- **User (Client)**: Uses `home` module (Home/Booking/Messages/Profile tabs)
- **Helper (Worker)**: Uses `helper_home` module (Home/Jobs/Messages/Profile tabs)
- **Role Storage**: `RoleService` via `Get.find<RoleService>()` (in-memory, resets on restart)
- **Role Parameter**: Passed via `Get.arguments` as `{'role': 'user'}` or `{'role': 'helper'}`

## Module Structure
Each module follows this pattern:
```
module_name/
  ├── bindings/
  │   └── module_binding.dart
  ├── controllers/
  │   └── module_controller.dart
  └── views/
      ├── module_view.dart
      └── widgets/ (optional)
```

## Naming Conventions
- Routes: kebab-case paths (`/helper-home`, `/apply-as-helper`)
- Classes: PascalCase (`HelperHomeController`, `ApplyHelperView`)
- Files: snake_case (`helper_home_controller.dart`, `apply_helper_view.dart`)
- Reactive vars: `.obs` suffix (`currentIndex.obs`, `isSelected.obs`)
- Widget builders: `_build` prefix (`_buildJobCard()`, `_buildStatusBadge()`)

## Shared Resources
- Colors: `AppColors` class (`lib/app/core/values/app_colors.dart`)
- Styles: `AppStyles` class (`lib/app/core/values/app_styles.dart`)
- Assets: `AppAssets` class (`lib/app/core/values/app_assets.dart`)
- Widgets: `CustomButton`, `CustomTextField` (`lib/app/core/widgets/`)

## Key Rules
1. Never modify existing user flow screens unless explicitly asked
2. All new screens use `Transition.rightToLeft` for navigation
3. Mock data only - no backend API calls
4. Chat messages render locally on send for instant UX
5. Use `Get.arguments` for passing data between routes
6. Helper-specific screens go under `lib/app/modules/helper/`
