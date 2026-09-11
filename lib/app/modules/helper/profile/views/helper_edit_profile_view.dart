import 'dart:async';
import 'dart:io';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HelperEditProfileView extends StatefulWidget {
  const HelperEditProfileView({super.key});

  @override
  State<HelperEditProfileView> createState() => _HelperEditProfileViewState();
}

class _HelperEditProfileViewState extends State<HelperEditProfileView> {
  // Personal Info
  late TextEditingController nameCtl;
  late TextEditingController emailCtl;
  late TextEditingController phoneCtl;
  late TextEditingController bioCtl;

  // Professional Details
  late TextEditingController priceCtl;
  late TextEditingController experienceCtl;
  late TextEditingController radiusCtl;
  late TextEditingController cityCtl;
  late TextEditingController languageCtl;

  // Location
  late TextEditingController addressCtl;
  double? selectedLatitude;
  double? selectedLongitude;
  final isSearchingAddress = false.obs;
  final addressSuggestions = <Map<String, dynamic>>[].obs;
  Timer? _debounce;

  // Portfolio Photos
  final existingPhotos = <String>[].obs;
  final newPhotoPaths = <String>[].obs;

  final isSaving = false.obs;
  final isUploadingAvatar = false.obs;
  final _picker = ImagePicker();
  String? _pickedAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = Get.find<AuthService>().currentUser.value;

    nameCtl = TextEditingController(text: user?.name ?? '');
    emailCtl = TextEditingController(text: user?.email ?? '');
    phoneCtl = TextEditingController(text: user?.phone ?? '');
    bioCtl = TextEditingController(text: user?.bio ?? '');

    priceCtl = TextEditingController(
      text: user?.pricePerHour != null ? user!.pricePerHour!.toStringAsFixed(0) : '',
    );
    experienceCtl = TextEditingController(
      text: user?.experience != null ? user!.experience.toString() : '',
    );
    radiusCtl = TextEditingController(
      text: user?.serviceRadius != null ? user!.serviceRadius!.toStringAsFixed(0) : '',
    );
    cityCtl = TextEditingController(
      text: user?.address != null && user!.address!.contains(',')
          ? user.address!.split(',').first.trim()
          : '',
    );
    languageCtl = TextEditingController(text: user?.language ?? '');

    addressCtl = TextEditingController(text: user?.address ?? '');
    selectedLatitude = user?.latitude;
    selectedLongitude = user?.longitude;

    if (user?.profilePhotos != null) {
      existingPhotos.assignAll(user!.profilePhotos!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    nameCtl.dispose();
    emailCtl.dispose();
    phoneCtl.dispose();
    bioCtl.dispose();
    priceCtl.dispose();
    experienceCtl.dispose();
    radiusCtl.dispose();
    cityCtl.dispose();
    languageCtl.dispose();
    addressCtl.dispose();
    super.dispose();
  }

  // ─── Avatar ─────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() => _pickedAvatarPath = image.path);
      isUploadingAvatar.value = true;

      final key = await _uploadFile(image.path);
      if (key != null) {
        final api = Get.find<ApiClient>();
        final response = await api.patch(
          ApiConstants.userMe,
          data: {'avatar': key},
        );

        if (response.success) {
          await Get.find<AuthService>().getMe();
          if (mounted) {
            Get.snackbar(
              'Success',
              'Profile photo updated',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } else {
          if (mounted) {
            Get.snackbar(
              'Error',
              response.message ?? 'Failed to update photo',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            'Failed to upload image',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to pick image',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  // ─── Work Samples (Portfolio Photos) ───────────────────

  Future<void> _pickWorkSamplePhotos() async {
    final totalPhotos = existingPhotos.length + newPhotoPaths.length;
    if (totalPhotos >= 5) {
      Get.snackbar(
        'Limit Reached',
        'helper_max_photos'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (images.isEmpty) return;

      for (final img in images) {
        if (existingPhotos.length + newPhotoPaths.length < 5) {
          newPhotoPaths.add(img.path);
        } else {
          break;
        }
      }
    } catch (_) {
      AppFeedback.error('Failed to pick photos');
    }
  }

  void _removeExistingPhoto(int index) {
    existingPhotos.removeAt(index);
  }

  void _removeNewPhoto(int index) {
    newPhotoPaths.removeAt(index);
  }

  // ─── Location & Address ─────────────────────────────────

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().length < 3) {
      addressSuggestions.clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddress(query.trim());
    });
  }

  Future<void> _searchAddress(String query) async {
    isSearchingAddress.value = true;
    try {
      final locService = Get.find<LocationService>();
      final results = await locService.forwardGeocode(query);
      addressSuggestions.assignAll(results);
    } catch (_) {
      addressSuggestions.clear();
    } finally {
      if (mounted) {
        isSearchingAddress.value = false;
      }
    }
  }

  void _selectAddress(Map<String, dynamic> item) {
    final address = (item['displayName'] ?? item['address']) as String? ?? '';
    final lat = ((item['lat'] ?? item['latitude']) as num?)?.toDouble();
    final lon = ((item['lon'] ?? item['longitude']) as num?)?.toDouble();

    addressCtl.text = address;
    selectedLatitude = lat;
    selectedLongitude = lon;
    addressSuggestions.clear();
  }

  Future<void> _useCurrentLocation() async {
    try {
      final locService = Get.find<LocationService>();
      final address = await locService.getCurrentAddress();
      if (address != null && address.isNotEmpty) {
        addressCtl.text = address;
        selectedLatitude = locService.currentLatitude.value;
        selectedLongitude = locService.currentLongitude.value;
        addressSuggestions.clear();
        Get.snackbar(
          'Location',
          'Updated to current location',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Location',
          'Could not determine current address',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (_) {
      Get.snackbar('Location', 'Failed to retrieve location', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // ─── Upload & Save ──────────────────────────────────────

  Future<String?> _uploadFile(String filePath) async {
    try {
      final fileName = filePath.split(Platform.isWindows ? '\\' : '/').last;
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final api = Get.find<ApiClient>();
      final response = await api.upload(
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

  Future<void> _saveProfile() async {
    isSaving.value = true;
    try {
      // 1. Upload any newly picked work sample photos
      final finalPhotos = <String>[...existingPhotos];
      for (final path in newPhotoPaths) {
        final key = await _uploadFile(path);
        if (key != null) {
          finalPhotos.add(key);
        }
      }

      // Validate email if provided
      if (emailCtl.text.trim().isNotEmpty && !GetUtils.isEmail(emailCtl.text.trim())) {
        Get.snackbar(
          'Error',
          'Please enter a valid email address',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // 2. Prepare payload
      final data = <String, dynamic>{
        if (nameCtl.text.trim().isNotEmpty) 'name': nameCtl.text.trim(),
        if (emailCtl.text.trim().isNotEmpty) 'email': emailCtl.text.trim(),
        if (phoneCtl.text.trim().isNotEmpty) 'phone': phoneCtl.text.trim(),
        if (bioCtl.text.trim().isNotEmpty) 'bio': bioCtl.text.trim(),
        if (cityCtl.text.trim().isNotEmpty) 'city': cityCtl.text.trim(),
        if (languageCtl.text.trim().isNotEmpty) 'language': languageCtl.text.trim(),
        if (priceCtl.text.trim().isNotEmpty)
          'pricePerHour': double.tryParse(priceCtl.text.trim()),
        if (experienceCtl.text.trim().isNotEmpty)
          'experience': int.tryParse(experienceCtl.text.trim()),
        if (radiusCtl.text.trim().isNotEmpty)
          'serviceRadius': double.tryParse(radiusCtl.text.trim()),
        if (addressCtl.text.trim().isNotEmpty) 'address': addressCtl.text.trim(),
        if (selectedLatitude != null) 'latitude': selectedLatitude,
        if (selectedLongitude != null) 'longitude': selectedLongitude,
        'profilePhotos': finalPhotos,
      };

      final api = Get.find<ApiClient>();
      final response = await api.patch(ApiConstants.userMe, data: data);

      if (response.success) {
        await Get.find<AuthService>().getMe();
        if (mounted) {
          Get.back();
          Get.snackbar(
            'Success',
            'helper_profile_updated'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        if (mounted) {
          Get.snackbar(
            'Error',
            response.message ?? 'Update failed',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSaving.value = false;
    }
  }

  // ─── Build UI ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'helper_edit_profile'.tr,
          style: AppStyles.h2Of(context).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildAvatarSection(context),
            const SizedBox(height: 30),

            // ── Section 1: Personal Information
            _buildSectionHeader(context, 'helper_personal_info'.tr),
            const SizedBox(height: 16),
            _buildField(context, 'apply_full_name'.tr, nameCtl),
            const SizedBox(height: 16),
            _buildField(context, 'apply_email'.tr, emailCtl, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildField(context, 'helper_phone'.tr, phoneCtl, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildBioField(context),
            const SizedBox(height: 30),

            // ── Section 2: Professional Details
            _buildSectionHeader(context, 'helper_pro_info'.tr),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    context,
                    'helper_hourly_rate'.tr,
                    priceCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    context,
                    'helper_experience_years'.tr,
                    experienceCtl,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(context, 'helper_city'.tr, cityCtl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(context, 'helper_language'.tr, languageCtl),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              context,
              'helper_service_radius'.tr,
              radiusCtl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 30),

            // ── Section 3: Work Samples (Portfolio Photos)
            _buildPortfolioSection(context),
            const SizedBox(height: 30),

            // ── Section 4: Service Location
            _buildLocationSection(context),
            const SizedBox(height: 36),

            // Action Buttons
            _buildBottomButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppStyles.h2Of(context).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final user = Get.find<AuthService>().currentUser.value;
    final avatar = user?.avatar;

    return Center(
      child: Obx(() => Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.cardColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipOval(
              child: _pickedAvatarPath != null
                  ? Image.file(
                      File(_pickedAvatarPath!),
                      fit: BoxFit.cover,
                    )
                  : avatar != null && avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(context),
                        )
                      : _buildAvatarPlaceholder(context),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: isUploadingAvatar.value ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF5AB9A7),
                  shape: BoxShape.circle,
                ),
                child: isUploadingAvatar.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context) {
    return Container(
      color: context.inputFillLight,
      child: Icon(Icons.person, size: 50, color: context.textHintColor),
    );
  }

  Widget _buildField(
    BuildContext context,
    String label,
    TextEditingController ctl, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: ctl,
          readOnly: readOnly,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? context.inputFillLight : context.inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: readOnly
                  ? BorderSide(color: context.borderSubtle)
                  : const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'helper_bio'.tr,
          style: AppStyles.bodyMediumOf(context).copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: bioCtl,
          maxLines: 5,
          minLines: 3,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'helper_enter_bio'.tr,
            hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            filled: true,
            fillColor: context.inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection(BuildContext context) {
    return Obx(() {
      final total = existingPhotos.length + newPhotoPaths.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(context, 'helper_work_samples'.tr),
              Text(
                '$total/5',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'helper_work_samples_desc'.tr,
            style: AppStyles.bodyMedium.copyWith(fontSize: 12, color: context.textHintColor),
          ),
          const SizedBox(height: 14),

          // Photo grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Existing photos
              for (int i = 0; i < existingPhotos.length; i++)
                _buildPhotoThumbnail(
                  context,
                  imageWidget: Image.network(
                    existingPhotos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                  ),
                  onRemove: () => _removeExistingPhoto(i),
                ),

              // New picked photos
              for (int i = 0; i < newPhotoPaths.length; i++)
                _buildPhotoThumbnail(
                  context,
                  imageWidget: Image.file(
                    File(newPhotoPaths[i]),
                    fit: BoxFit.cover,
                  ),
                  onRemove: () => _removeNewPhoto(i),
                ),

              // Add Photo Button if under 5
              if (total < 5)
                GestureDetector(
                  onTap: _pickWorkSamplePhotos,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: context.inputFillColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPhotoThumbnail(
    BuildContext context, {
    required Widget imageWidget,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 90,
            height: 90,
            child: imageWidget,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'helper_location_section'.tr),
        const SizedBox(height: 12),
        TextField(
          controller: addressCtl,
          onChanged: _onAddressChanged,
          style: TextStyle(color: context.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'helper_search_address'.tr,
            hintStyle: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: Obx(() => isSearchingAddress.value
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const SizedBox.shrink()),
            filled: true,
            fillColor: context.inputFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Auto-complete suggestion dropdown
        Obx(() {
          if (addressSuggestions.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addressSuggestions.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: context.borderSubtle),
              itemBuilder: (context, index) {
                final result = addressSuggestions[index];
                final displayName = (result['displayName'] ?? result['address']) as String? ?? '';

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                  title: Text(
                    displayName,
                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectAddress(result),
                );
              },
            ),
          );
        }),

        // Use Current Location Button
        InkWell(
          onTap: _useCurrentLocation,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'helper_use_gps'.tr,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Get.back(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('btn_cancel'.tr, style: AppStyles.buttonText.copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(() => ElevatedButton(
            onPressed: isSaving.value ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: isSaving.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('helper_save_changes'.tr, style: AppStyles.buttonText),
          )),
        ),
      ],
    );
  }
}

