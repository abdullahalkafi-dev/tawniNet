import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/category_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awnneaapp/app/core/utils/image_picker_errors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/widgets/helper_form_fields.dart';
import 'package:awnneaapp/app/services/role_service.dart';

class ApplyHelperController extends GetxController with WidgetsBindingObserver {
  late final ApiClient _api;
  final _picker = ImagePicker();

  // Text controllers
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final priceController = TextEditingController();
  final experienceController = TextEditingController();
  final serviceRadiusController = TextEditingController();
  final bioController = TextEditingController();

  // Dropdown state
  final selectedLanguages = <String>[].obs;
  final selectedCity = RxnString();
  final selectedServiceType = Rxn<Category>();

  // Upload state
  final profilePhotoPath = RxnString();
  final profilePhotoKey = RxnString();
  final selectedPhotoPaths = <String>[].obs;
  final uploadedPhotoKeys = <String>[].obs;

  // Didit KYC state
  final isStartingKyc = false.obs;
  final isSyncingKyc = false.obs;
  final activeDiditSessionId = RxnString();

  // Loading states
  final isLoading = false.obs;
  final isLoadingCategories = false.obs;
  final isUploadingPhoto = false.obs;

  // Options
  final categories = <Category>[].obs;
  final categoriesFailed = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _api = Get.find<ApiClient>();
    _loadUserProfile();
    fetchCategories();
  }

  int _resumePollCount = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When user returns from the Didit verification browser
      final user = Get.find<AuthService>().currentUser.value;
      if (user?.helperApplicationStatus == 'approved') return;
      if (isSyncingKyc.value) return;
      if (activeDiditSessionId.value != null || user?.diditSessionId != null) {
        _pollKycOnResume();
      }
    }
  }

  void _pollKycOnResume() async {
    final initialUser = Get.find<AuthService>().currentUser.value;
    if (initialUser?.helperApplicationStatus == 'approved') return;

    _resumePollCount = 0;
    while (_resumePollCount < 4) {
      if (isClosed) return;
      final user = Get.find<AuthService>().currentUser.value;
      if (user?.helperApplicationStatus == 'approved' ||
          user?.helperApplicationStatus == 'rejected' ||
          user?.diditStatus == 'In Review' ||
          user?.helperApplicationStatus == 'pending_appeal') {
        break;
      }
      await syncKycStatus(showFeedback: false);
      _resumePollCount++;
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  void _loadUserProfile() {
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      if (user != null) {
        if (!user.hasLocation) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offAllNamed(Routes.locationAllow);
          });
          return;
        }

        fullNameController.text = user.name;
        phoneController.text = user.phone ?? '';
        emailController.text = user.email ?? '';
        if (user.avatar != null && user.avatar!.isNotEmpty) {
          profilePhotoKey.value = user.avatar;
        }
        if (user.profilePhotos != null && user.profilePhotos!.isNotEmpty) {
          uploadedPhotoKeys.assignAll(user.profilePhotos!);
        }
        selectedCity.value = matchMoroccanCity(user.city, user.address);
        selectedLanguages.assignAll(parseHelperLanguages(user.language));
        if (user.bio != null) bioController.text = user.bio!;
        if (user.age != null) ageController.text = user.age.toString();
        if (user.pricePerHour != null) priceController.text = user.pricePerHour.toString();
        if (user.experience != null) experienceController.text = user.experience.toString();
        if (user.serviceRadius != null) serviceRadiusController.text = user.serviceRadius.toString();
      }
    } catch (_) {}
  }

  // ─── Categories ─────────────────────────────────────────

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    categoriesFailed.value = false;
    try {
      final categoryService = Get.find<CategoryService>();
      final result = await categoryService.getActiveCategories();
      categories.assignAll(result);
      final user = Get.find<AuthService>().currentUser.value;
      if (user?.serviceType != null && categories.isNotEmpty) {
        selectedServiceType.value = categories.firstWhereOrNull((c) => c.id == user!.serviceType || c.name == user.serviceType);
      }
    } catch (e) {
      // No invented categories: the form shows an error with a retry button.
      if (categories.isEmpty) categoriesFailed.value = true;
    } finally {
      if (!isClosed) {
        isLoadingCategories.value = false;
      }
    }
  }

  // ─── Profile Photo ──────────────────────────────────────

  Future<void> pickProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image == null) return;

      profilePhotoPath.value = image.path;
      // Upload immediately
      final key = await _uploadFile(image.path, 'image');
      if (key != null) {
        profilePhotoKey.value = key;
        // Also save to user profile
        try {
          await Get.find<AuthService>().updateProfile({'avatar': key});
        } catch (e) {
          _showError(e);
        }
      }
    } catch (e) {
      _showError(imagePickerErrorMessage(e));
    }
  }

  // ─── Photos ─────────────────────────────────────────────

  Future<void> pickPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (images.isEmpty) return;

      for (final image in images) {
        if (uploadedPhotoKeys.length + selectedPhotoPaths.length >= 5) {
          _showError('ui_maximum_5_photos_allowed'.tr);
          break;
        }
        selectedPhotoPaths.add(image.path);
        // Upload in background
        _uploadPhotoInBackground(image.path);
      }
    } catch (e) {
      _showError(imagePickerErrorMessage(e));
    }
  }

  Future<void> _uploadPhotoInBackground(String path) async {
    final key = await _uploadFile(path, 'image');
    if (!selectedPhotoPaths.contains(path)) {
      // User removed this photo while it was uploading
      return;
    }
    selectedPhotoPaths.remove(path);
    if (key != null) {
      uploadedPhotoKeys.add(key);
      try {
        await Get.find<AuthService>().updateProfile({'profilePhotos': uploadedPhotoKeys.toList()});
      } catch (e) {
        _showError(e);
      }
    } else {
      _showError('ui_failed_to_upload_an_image'.tr);
    }
  }

  Future<void> removePhoto(int index) async {
    if (index < uploadedPhotoKeys.length) {
      uploadedPhotoKeys.removeAt(index);
      try {
        await Get.find<AuthService>().updateProfile({'profilePhotos': uploadedPhotoKeys.toList()});
      } catch (e) {
        _showError(e);
      }
    } else {
      final pendingIndex = index - uploadedPhotoKeys.length;
      if (pendingIndex >= 0 && pendingIndex < selectedPhotoPaths.length) {
        selectedPhotoPaths.removeAt(pendingIndex);
      }
    }
  }

  // ─── Upload Helper ──────────────────────────────────────

  Future<String?> _uploadFile(String filePath, String type) async {
    try {
      final fileName = filePath.split('/').last;

      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final endpoint = type == 'image'
          ? ApiConstants.uploadImage
          : ApiConstants.uploadDocument;

      final response = await _api.upload(
        endpoint,
        formData: formData,
      );

      if (response.success && response.data != null) {
        return response.data['key'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── Didit Automated KYC Launcher & Sync ────────────────

  Future<void> launchDiditKyc() async {
    isStartingKyc.value = true;
    try {
      final authService = Get.find<AuthService>();
      final sessionData = await authService.createDiditSession();
      final sessionUrl = sessionData['url'] as String?;
      final sessionId = sessionData['sessionId'] as String?;

      if (sessionId != null) {
        activeDiditSessionId.value = sessionId;
      }

      if (sessionUrl != null && sessionUrl.isNotEmpty) {
        final uri = Uri.parse(sessionUrl);
        bool launched = false;
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          } catch (_) {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        }
        if (!launched) {
          throw Exception('Could not open verification browser session. Please check your browser.');
        }
      } else {
        throw Exception('Verification session URL was not returned by the server');
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (!isClosed) {
        isStartingKyc.value = false;
      }
    }
  }

  Future<void> syncKycStatus({bool showFeedback = true}) async {
    isSyncingKyc.value = true;
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      final sessionId = activeDiditSessionId.value ?? user?.diditSessionId;
      if (sessionId != null && sessionId.isNotEmpty) {
        await authService.syncDiditSession(sessionId);
      }
      await authService.getMe();
      final updatedUser = authService.currentUser.value;

      if (updatedUser?.helperApplicationStatus == 'approved') {
        if (Get.isRegistered<RoleService>()) {
          Get.find<RoleService>().setUserRole('helper');
        }
        AppSnackbar.showSuccess('ui_kyc_verification_approved_welcome_to_3awninet'.tr);
        Get.offAllNamed(Routes.helperHome);
        return;
      } else if (updatedUser?.helperApplicationStatus == 'rejected') {
        AppSnackbar.showError(updatedUser?.rejectionReason ?? 'ui_verification_was_not_approved'.tr);
        Get.offAllNamed(Routes.applicationRejected);
        return;
      } else if (updatedUser?.diditStatus == 'In Review' || updatedUser?.helperApplicationStatus == 'pending_appeal') {
        Get.offAllNamed(Routes.applicationPending);
        return;
      }

      if (showFeedback) {
        AppSnackbar.showSuccess('ui_verification_status_value'.trParams({'status': updatedUser?.diditStatus ?? 'status_in_progress'.tr}));
      }
    } catch (e) {
      if (showFeedback) {
        _showError(e);
      }
    } finally {
      if (!isClosed) {
        isSyncingKyc.value = false;
      }
    }
  }

  // ─── Step 1: Submit Form & Proceed to KYC ────────────────

  Future<void> submitFormStep() async {
    // 1. Rigorous Frontend Validations
    if (profilePhotoKey.value == null || profilePhotoKey.value!.isEmpty) {
      _showError('ui_please_upload_a_profile_photo'.tr);
      return;
    }
    if (ageController.text.trim().isEmpty) {
      _showError('ui_please_enter_your_age'.tr);
      return;
    }
    final age = int.tryParse(ageController.text.trim());
    if (age == null || age < 18) {
      _showError('ui_must_be_13_years_or_older_to'.tr);
      return;
    }
    final city = selectedCity.value;
    if (city == null || city.isEmpty) {
      _showError('apply_city_required'.tr);
      return;
    }
    if (selectedLanguages.isEmpty) {
      _showError('apply_languages_required'.tr);
      return;
    }
    if (emailController.text.trim().isNotEmpty && !GetUtils.isEmail(emailController.text.trim())) {
      _showError('ui_please_enter_a_valid_email_address'.tr);
      return;
    }
    if (selectedServiceType.value == null) {
      _showError('ui_please_select_a_service_category'.tr);
      return;
    }
    if (priceController.text.trim().isEmpty) {
      _showError('ui_please_enter_your_hourly_rate_mad'.tr);
      return;
    }
    final price = double.tryParse(priceController.text.trim());
    if (price == null || price <= 0) {
      _showError('ui_hourly_rate_must_be_greater_than_0'.tr);
      return;
    }
    final minRate = selectedServiceType.value?.minHourlyRate;
    if (minRate != null && price < minRate) {
      _showError('price_below_min_hourly'.trParams({
        'category': selectedServiceType.value!.name,
        'min': minRate.toStringAsFixed(0),
      }));
      return;
    }
    if (experienceController.text.trim().isEmpty) {
      _showError('ui_please_enter_your_experience_in_years'.tr);
      return;
    }
    final experience = int.tryParse(experienceController.text.trim());
    if (experience == null || experience < 0) {
      _showError('ui_experience_cannot_be_negative'.tr);
      return;
    }
    if (serviceRadiusController.text.trim().isEmpty) {
      _showError('ui_please_enter_your_service_radius_km'.tr);
      return;
    }
    final radius = double.tryParse(serviceRadiusController.text.trim());
    if (radius == null || radius <= 0) {
      _showError('ui_service_radius_must_be_greater_than_0'.tr);
      return;
    }
    // Clients decide based on real work photos, so a portfolio is required.
    if (selectedPhotoPaths.isNotEmpty) {
      _showError('apply_photos_uploading'.tr);
      return;
    }
    if (uploadedPhotoKeys.isEmpty) {
      _showError('apply_work_photo_required'.tr);
      return;
    }

    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();

      final response = await _api.post(
        ApiConstants.helperApply,
        data: {
          'age': age,
          'city': city,
          'language': selectedLanguages.join(', '),
          'serviceType': selectedServiceType.value!.id,
          'pricePerHour': price,
          'experience': experience,
          'serviceRadius': radius,
          'profilePhotos': uploadedPhotoKeys.toList(),
          if (profilePhotoKey.value != null)
            'avatar': profilePhotoKey.value,
          if (phoneController.text.trim().isNotEmpty)
            'phone': phoneController.text.trim(),
          if (emailController.text.trim().isNotEmpty)
            'email': emailController.text.trim(),
          if (bioController.text.trim().isNotEmpty)
            'bio': bioController.text.trim(),
        },
      );

      if (isClosed) return;

      if (response.success) {
        await authService.getMe();
        if (isClosed) return;
        AppSnackbar.showSuccess('ui_information_saved_proceeding_to_id_verification'.tr);
        Get.toNamed(Routes.helperKycVerification);
      } else {
        throw Exception(response.message ?? 'Failed to save application information');
      }
    } catch (e) {
      if (isClosed) return;
      _showError(e);
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  // Alias for backward compatibility if any old view references submitApplication
  Future<void> submitApplication() => submitFormStep();

  // ─── Other ──────────────────────────────────────────────

  void updateAndReapply() {
    Get.back();
  }

  void logout() async {
    final authService = Get.find<AuthService>();
    await authService.logout();
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    fullNameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    emailController.dispose();
    priceController.dispose();
    experienceController.dispose();
    serviceRadiusController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
