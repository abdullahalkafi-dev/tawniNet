# AGENTS.md - Development Guidelines

## Architecture
- **Framework**: Flutter with GetX (v4.6.6)
- **Pattern**: Module-based MVC (GetView + GetxController + Bindings)
- **Routing**: GetX named routing with `GetPage` definitions
- **State**: Reactive `.obs` observables with `Obx(() => ...)` widgets

## Role System
- **User (Client)**: Uses `home` module (Home/Booking/Messages/Profile tabs)
- **Helper (Worker)**: Uses `helper_home` module (Home/Jobs/Messages/Profile tabs)
- **Role Storage**: `RoleService` via `Get.find<RoleService>()` (persisted to secure storage)
- **Role Source**: Backend `user.role` field in auth response (not client-side selection)

## API Integration
- **HTTP Client**: Dio with interceptors (`lib/app/services/api_client.dart`)
- **Base URL**: `http://10.0.2.2:5000/api/v1` (Android emulator)
- **Token Storage**: `flutter_secure_storage` via `StorageService`
- **Auth State**: `AuthService` (GetxService, permanent) — reactive `currentUser`, `isLoggedIn`
- **Cache Invalidation**: `RefetchService` — register callbacks, invalidate by key (RTK-Query style)
- **Pull-to-Refresh**: `RefreshIndicator` on data-list views, calls controller's `refreshData()`
- **Socket.IO**: Stub only (`SocketService`) — backend sockets not ready yet

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

### CustomTextField
Reusable text field widget. Supports optional params:
- `keyboardType` — e.g. `TextInputType.number` for numeric fields
- `inputFormatters` — e.g. `[FilteringTextInputFormatter.digitsOnly]` to restrict to numbers
- `isPassword` / `isVisible` / `onToggleVisibility` — password toggle
- `validator` — form validation

### LocationService
Centralized geocoding via backend. Use `Get.find<LocationService>()`.
- `reverseGeocode(lat, lon)` → `{ address, city, country, lat, lon }` or null
- `forwardGeocode(query, {limit})` → `List<{ displayName, lat, lon, city, country }>`
- 1s debounce required on search inputs to stay within LocationIQ free tier

## Key Rules
1. Never modify existing user flow screens unless explicitly asked
2. All new screens use `Transition.rightToLeft` for navigation
3. Chat messages render locally on send for instant UX
4. Use `Get.arguments` for passing data between routes
5. Helper-specific screens go under `lib/app/modules/helper/`
6. Category dropdowns must send `_id` (ObjectId), not name — use `Rxn<Category>` + `_buildCategoryDropdownField`
7. Location geocoding goes through backend (`/geocoding/reverse`, `/geocoding/forward`) — never call LocationIQ directly from Flutter
8. Address is best-effort: if geocoding fails, omit `address` field from request (don't send null)

---

## CRITICAL: GetX Registration Rules

**Breaking these rules causes runtime crashes. Read before writing any service or controller.**

### Rule 1: Never use `Get.put` with async values

```dart
// WRONG — registers Future<AuthService>, not AuthService
await Get.put(AuthService().init(), permanent: true);

// CORRECT — resolve first, then register
final authService = AuthService();
await authService.init();
Get.put(authService, permanent: true);
```

### Rule 2: Never use `Get.find` in field initializers

```dart
// WRONG — executes at construction time, fragile coupling to registration order
class AuthService extends GetxService {
  final _api = Get.find<ApiClient>();  // crashes if ApiClient not registered yet
}

// CORRECT — use late final, resolve in init()
class AuthService extends GetxService {
  late final ApiClient _api;
  
  Future<AuthService> init() async {
    _api = Get.find<ApiClient>();  // explicit, safe, documented dependency
    // ...
  }
}
```

### Rule 3: Service registration order in main.dart matters

```dart
// CORRECT order — dependencies first, dependents after
Get.put(StorageService(), permanent: true);       // no deps
Get.put(ApiClient(storageService), permanent: true);  // depends on StorageService
Get.put(RoleService(), permanent: true);           // no deps
Get.put(CategoryService(), permanent: true);       // depends on ApiClient
Get.put(AuthService().init(), permanent: true);    // depends on ApiClient, StorageService, RoleService
```

### Rule 4: Bindings use `Get.lazyPut`, not `Get.put` (except SplashBinding)

```dart
// CORRECT — lazy loading for controllers
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}

// EXCEPTION — SplashBinding uses Get.put (eager) because splash loads first
class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
```

### Rule 5: When adding a new service, always check

1. Does it have async init? → Use `Get.put` with resolved instance, not `Get.putAsync` with Future
2. Does it depend on other services? → Register dependencies first in `main.dart`
3. Does it use `Get.find`? → Move to `late final` + `init()` pattern
4. Is it a GetxService (permanent)? → Register in `main.dart` before `runApp()`
5. Is it a controller (per-screen)? → Register in binding via `Get.lazyPut`

### Rule 6: Always check `isClosed` before navigation or state updates in async methods

```dart
// WRONG — crashes after Get.offAllNamed disposes the widget
Future<void> login() async {
  isLoading.value = true;
  try {
    await authService.login(...);
    Get.offAllNamed(Routes.home);
  } finally {
    isLoading.value = false;  // ERROR: widget already disposed!
  }
}

// CORRECT — guard with isClosed
Future<void> login() async {
  isLoading.value = true;
  try {
    await authService.login(...);
    if (isClosed) return;
    Get.offAllNamed(Routes.home);
  } catch (e) {
    if (isClosed) return;
    _showError(e.toString());
  } finally {
    if (!isClosed) {
      isLoading.value = false;
    }
  }
}
```

**Why this happens:** `Get.offAllNamed()` disposes the current route and all previous routes. If an async method is still running (e.g., in a `finally` block), it tries to update reactive state on a disposed controller, triggering Flutter's `_dependents.isEmpty` assertion.

**Rule:** Every async method in a controller must check `isClosed` before:
- Calling `Get.offAllNamed()` or `Get.toNamed()`
- Calling `Get.snackbar()`
- Updating `.obs` variables in `finally` blocks
