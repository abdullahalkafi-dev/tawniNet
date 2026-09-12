import 'package:awnneaapp/app/data/models/user_model.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/refetch_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/constants/refetch_keys.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  final _api = Get.find<ApiClient>();

  // Profile data
  final userProfile = Rxn<UserProfile>();
  final isLoading = false.obs;
  final isUpdating = false.obs;
  final isUploadingAvatar = false.obs;

  // Edit Profile fields
  final name = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final bio = ''.obs;
  final address = ''.obs;
  final gender = 'Male'.obs;

  // Avatar
  final _picker = ImagePicker();
  String? pickedAvatarPath;

  // Notification toggles
  final notificationEnabled = true.obs;
  final soundEnabled = true.obs;
  final vibrateEnabled = false.obs;
  final paymentsEnabled = true.obs;
  final cashbackEnabled = false.obs;
  final appUpdatesEnabled = false.obs;
  final newServiceEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    Get.find<RefetchService>().register(
      RefetchKeys.userProfile,
      fetchProfile,
    );
    fetchProfile();
    // Keep controllers in sync when fetch finishes (Edit Profile page).
    ever(userProfile, (_) => _syncFieldsFromProfile());
  }

  @override
  void onClose() {
    Get.find<RefetchService>().unregister(RefetchKeys.userProfile);
    super.onClose();
  }

  void clear() {
    userProfile.value = null;
    name.value = '';
    email.value = '';
    phone.value = '';
    bio.value = '';
    address.value = '';
    pickedAvatarPath = null;
  }

  // ─── Fetch Profile ──────────────────────────────────────

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final authService = Get.find<AuthService>();
      await authService.getMe();
      final user = authService.currentUser.value;
      if (user != null) {
        // Fetch full profile
        final response = await _api.get(
          ApiConstants.userMe,
          fromData: (data) => data,
        );
        if (response.success && response.data != null) {
          userProfile.value = UserProfile.fromJson(response.data);
          _syncFieldsFromProfile();
        }
      }
    } catch (e) {
      // Keep existing data on error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await fetchProfile();
  }

  // ─── Update Profile ─────────────────────────────────────

  Future<void> updateProfile({
    String? newName,
    String? newBio,
    String? newPhone,
    String? newEmail,
    String? newAddress,
  }) async {
    isUpdating.value = true;
    try {
      final trimmedEmail = newEmail?.trim() ?? '';
      final response = await _api.patch(
        ApiConstants.userMe,
        data: {
          if (newName != null && newName.trim().isNotEmpty)
            'name': newName.trim(),
          if (newBio != null) 'bio': newBio,
          if (newPhone != null) 'phone': newPhone,
          // Email is optional for clients — omit empty instead of sending "".
          if (trimmedEmail.isNotEmpty) 'email': trimmedEmail,
          if (newAddress != null) 'address': newAddress,
        },
      );

      if (isClosed) return;
      if (response.success) {
        await Get.find<RefetchService>().invalidate(RefetchKeys.userProfile);

        AppSnackbar.showSuccess('Profile updated successfully');
        Get.back();
      } else {
        throw Exception(response.message ?? 'Update failed');
      }
    } catch (e) {
      if (isClosed) return;
      AppSnackbar.showError(e);
    } finally {
      if (!isClosed) {
        isUpdating.value = false;
      }
    }
  }

  // ─── Avatar Upload ─────────────────────────────────────

  Future<void> pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image == null) return;

      pickedAvatarPath = image.path;
      isUploadingAvatar.value = true;

      final key = await _uploadFile(image.path);
      if (key != null) {
        final response = await _api.patch(
          ApiConstants.userMe,
          data: {'avatar': key},
        );

        if (isClosed) return;
        if (response.success) {
          await Get.find<AuthService>().getMe();
          await Get.find<RefetchService>().invalidate(RefetchKeys.userProfile);
          AppSnackbar.showSuccess('Profile photo updated');
        } else {
          AppSnackbar.showError(response.message ?? 'Failed to update photo');
        }
      } else {
        if (isClosed) return;
        AppSnackbar.showError('Failed to upload image');
      }
    } catch (e) {
      if (isClosed) return;
      AppSnackbar.showError(e);
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  Future<String?> _uploadFile(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _api.upload(
        ApiConstants.uploadImage,
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

  // ─── Helpers ────────────────────────────────────────────

  void _syncFieldsFromProfile() {
    final p = userProfile.value;
    if (p != null) {
      name.value = p.name;
      email.value = p.email ?? '';
      phone.value = p.phone ?? '';
      bio.value = p.bio ?? '';
      address.value = p.address ?? '';
    }
  }

  String get displayName => userProfile.value?.name ?? name.value;
  String get displayEmail => userProfile.value?.email ?? email.value;
  String? get displayAvatar => userProfile.value?.avatar;
}
