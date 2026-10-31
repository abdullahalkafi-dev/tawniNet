import 'dart:async';
import 'dart:io';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/data/models/home_models.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/category_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awnneaapp/app/core/utils/image_picker_errors.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/core/widgets/simple_time_picker.dart';

/// Job photos: keep in sync with Create Offer (max 4).
const int kJobMaxImages = 4;

class PostJobController extends GetxController {
  final titleController = TextEditingController();
  final dateController = TextEditingController();
  final startTimeController = TextEditingController();
  final endTimeController = TextEditingController();

  /// ISO `yyyy-MM-dd` — what we send to the API.
  String? _isoDate;
  final descController = TextEditingController();
  final addressController = TextEditingController();
  final budgetController = TextEditingController();

  final isHourly = true.obs;
  final isOnlinePayment = true.obs;

  final categories = <Category>[].obs;
  final selectedCategory = Rxn<Category>();
  final selectedImages = <String>[].obs;
  final uploadedImageUrls = <String>[].obs;

  final selectedLatitude = RxnDouble();
  final selectedLongitude = RxnDouble();

  final addressSuggestions = <Map<String, dynamic>>[].obs;
  final isSearchingAddress = false.obs;
  Timer? _debounce;

  final isLoadingCategories = false.obs;
  final categoriesFailed = false.obs;
  final isSubmitting = false.obs;

  /// "5 h × 100 MAD = 500 MAD" shown under the price field (null when not computable).
  final totalPreview = RxnString();

  /// Address text that matches the selected coordinates; typing anything else drops them.
  String _pickedAddress = '';

  final _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    _initUserAddress();
    budgetController.addListener(_recomputeTotal);
    startTimeController.addListener(_recomputeTotal);
    endTimeController.addListener(_recomputeTotal);
  }

  /// Server rule: hourly total = rate × hours (rounded to whole MAD).
  int? get _hourlyTotal {
    final rate = double.tryParse(budgetController.text.trim());
    final hours = AppDateTime.hoursBetween(startTimeController.text, endTimeController.text);
    if (rate == null || rate <= 0 || hours == null) return null;
    return (rate * hours).round();
  }

  void _recomputeTotal() {
    if (!isHourly.value) {
      totalPreview.value = null;
      return;
    }
    final total = _hourlyTotal;
    if (total == null) {
      totalPreview.value = null;
      return;
    }
    final hours = AppDateTime.hoursBetween(startTimeController.text, endTimeController.text)!;
    final rate = double.parse(budgetController.text.trim());
    totalPreview.value = 'post_total_preview'.trParams({
      'hours': _fmt(hours),
      'rate': _fmt(rate),
      'total': '$total',
    });
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  void _initUserAddress() {
    try {
      final user = Get.find<AuthService>().currentUser.value;
      if (user != null && user.address != null && user.address!.isNotEmpty) {
        addressController.text = user.address!;
        if (user.latitude != null && user.longitude != null) {
          selectedLatitude.value = user.latitude;
          selectedLongitude.value = user.longitude;
          _pickedAddress = user.address!;
        }
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
    } catch (e) {
      // No fake categories: a job posted with an invented id would be rejected anyway.
      categoriesFailed.value = true;
    } finally {
      if (!isClosed) {
        isLoadingCategories.value = false;
      }
    }
  }

  void selectCategory(Category cat) {
    selectedCategory.value = cat;
  }

  void toggleBudgetType(bool hourly) {
    isHourly.value = hourly;
    _recomputeTotal();
  }

  void toggleBudget(bool hourly) => toggleBudgetType(hourly);

  void togglePaymentMethod(bool online) {
    isOnlinePayment.value = online;
  }

  // ─── Address Search & Auto-complete ─────────────────────

  RxBool get isSearchingLocation => isSearchingAddress;
  RxList<Map<String, dynamic>> get searchResults => addressSuggestions;

  void searchAddress(String query) => onAddressChanged(query);

  void onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Editing the text invalidates the previously picked point.
    if (query.trim() != _pickedAddress) {
      selectedLatitude.value = null;
      selectedLongitude.value = null;
    }

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
      final results = await locService.searchPlaces(query);
      addressSuggestions.assignAll(results);
    } catch (_) {
      addressSuggestions.clear();
    } finally {
      if (!isClosed) {
        isSearchingAddress.value = false;
      }
    }
  }

  void selectSearchResult(Map<String, dynamic> result) {
    selectAddressSuggestion(result);
  }

  void selectAddressSuggestion(Map<String, dynamic> suggestion) {
    final address = (suggestion['displayName'] ?? suggestion['address']) as String? ?? '';
    final lat = ((suggestion['lat'] ?? suggestion['latitude']) as num?)?.toDouble();
    final lng = ((suggestion['lon'] ?? suggestion['longitude']) as num?)?.toDouble();

    addressController.text = address;
    _pickedAddress = address.trim();
    selectedLatitude.value = lat;
    selectedLongitude.value = lng;
    addressSuggestions.clear();
  }

  /// Called by the map picker.
  void setPickedLocation(String address, double lat, double lng) {
    addressController.text = address;
    _pickedAddress = address.trim();
    selectedLatitude.value = lat;
    selectedLongitude.value = lng;
    addressSuggestions.clear();
  }

  Future<void> useCurrentLocation() async {
    try {
      final locService = Get.find<LocationService>();
      final address = await locService.getCurrentAddress();
      final lat = locService.currentLatitude.value;
      final lng = locService.currentLongitude.value;
      if (address != null && address.isNotEmpty && lat != null && lng != null && lat != 0 && lng != 0) {
        setPickedLocation(address, lat, lng);
      } else {
        _showError('ui_could_not_determine_current_address'.tr);
      }
    } catch (e) {
      _showError(e);
    }
  }

  // ─── Date & Time Pickers ────────────────────────────────


  Future<void> pickDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.darkCard,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _isoDate = AppDateTime.toIsoDate(picked);
      dateController.text = AppDateTime.formatDateDisplay(_isoDate);
    }
  }

  Future<void> pickTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final initial = AppDateTime.tryParseTimeOfDay(controller.text) ?? TimeOfDay.now();
    final picked = await showSimpleTimePicker(context, initialTime: initial);
    if (picked != null) {
      controller.text = AppDateTime.formatTimeOfDay12h(picked);
    }
  }

  // ─── Image Picker ───────────────────────────────────────

  Future<void> pickImage() => pickImages();

  Future<void> pickImages() async {
    if (selectedImages.length >= kJobMaxImages) {
      AppFeedback.error(
        'ui_max_images_allowed'.trParams({'max': '$kJobMaxImages'}),
        title: 'ui_limit_reached_2'.tr,
      );
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isEmpty) return;

      var skipped = 0;
      for (final img in images) {
        if (selectedImages.length < kJobMaxImages) {
          selectedImages.add(img.path);
        } else {
          skipped++;
        }
      }

      if (skipped > 0) {
        AppFeedback.error(
          'ui_images_limit_skipped'.trParams({'max': '$kJobMaxImages', 'skipped': '$skipped'}),
          title: 'ui_limit_reached_2'.tr,
        );
      }
    } catch (e) {
      _showError(imagePickerErrorMessage(e));
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // ─── Upload Images to Backend ───────────────────────────

  Future<List<String>> _uploadImages() async {
    final api = Get.find<ApiClient>();
    final urls = <String>[];
    var failed = 0;

    for (final path in selectedImages) {
      try {
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(
            path,
            filename: path.split(Platform.pathSeparator).last,
          ),
        });

        final response = await api.upload(
          ApiConstants.uploadImage,
          formData: formData,
        );

        if (response.success && response.data != null) {
          final key = (response.data['key'] ?? response.data['url']) as String?;
          if (key != null && key.isNotEmpty) {
            urls.add(key);
            continue;
          }
        }
        failed++;
      } catch (_) {
        failed++;
      }
    }

    if (failed > 0) {
      throw Exception(
        failed == selectedImages.length
            ? 'ui_failed_to_upload_images_retry'.tr
            : 'ui_failed_to_upload_some_images_retry'.trParams({
                'failed': '$failed',
                'total': '${selectedImages.length}',
              }),
      );
    }

    return urls;
  }

  // ─── Submit Job ─────────────────────────────────────────

  void postJob() {
    // Validate required fields
    if (titleController.text.trim().isEmpty) {
      _showError('ui_please_enter_a_job_title'.tr);
      return;
    }
    if (budgetController.text.trim().isEmpty) {
      _showError('ui_please_enter_a_budget'.tr);
      return;
    }
    if (selectedCategory.value == null) {
      _showError('ui_please_select_a_category'.tr);
      return;
    }

    String? isoDate = _isoDate;
    if (isoDate == null && dateController.text.trim().isNotEmpty) {
      final parsed = AppDateTime.tryParseDate(dateController.text);
      if (parsed != null) isoDate = AppDateTime.toIsoDate(parsed);
    }
    if (isoDate == null || isoDate.isEmpty) {
      _showError('ui_please_select_a_preferred_date'.tr);
      return;
    }

    final minRate = selectedCategory.value!.minHourlyRate;
    final budget = double.tryParse(budgetController.text.trim()) ?? 0;
    if (isHourly.value && minRate != null && budget < minRate) {
      _showError('price_below_min_hourly'.trParams({
        'category': selectedCategory.value!.name,
        'min': minRate.toStringAsFixed(0),
      }));
      return;
    }

    // Hourly jobs are billed from the time range, so both ends are required.
    final timeError = AppDateTime.validateTimeRange(
      startTimeController.text,
      endTimeController.text,
      required: isHourly.value,
    );
    if (timeError != null) {
      _showError(timeError);
      return;
    }

    if (addressController.text.trim().isEmpty) {
      _showError('post_address_required'.tr);
      return;
    }
    if (selectedLatitude.value == null || selectedLongitude.value == null) {
      _showError('post_pick_suggestion'.tr);
      return;
    }

    // Show payment dialog
    _showPaymentDialog();
  }

  void _showPaymentDialog() {
    final isDark = Get.isDarkMode;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ui_select_payment_method'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                ),
              ),
              if (isHourly.value && totalPreview.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  totalPreview.value!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ] else if (!isHourly.value) ...[
                const SizedBox(height: 12),
                Text(
                  'post_total_fixed'.trParams({'total': budgetController.text.trim()}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _buildPaymentOption(
                        'ui_online_payment'.tr,
                        Icons.credit_card,
                        isOnlinePayment.value,
                        () => isOnlinePayment.value = true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(
                      () => _buildPaymentOption(
                        'ui_cash'.tr,
                        Icons.account_balance_wallet_outlined,
                        !isOnlinePayment.value,
                        () => isOnlinePayment.value = false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey[300]!),
                      ),
                      child: Text(
                        'btn_cancel'.tr,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // Close dialog
                        _submitJob();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ui_continue'.tr,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitJob() async {
    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      // Upload images first
      if (selectedImages.isNotEmpty) {
        uploadedImageUrls.clear();
        final urls = await _uploadImages();
        uploadedImageUrls.assignAll(urls);
      }

      // Build job payload
      final data = <String, dynamic>{
        'title': titleController.text.trim(),
        'budget': double.tryParse(budgetController.text.trim()) ?? 0,
        'budgetType': isHourly.value ? 'hourly' : 'fixed',
        'paymentMethod': isOnlinePayment.value ? 'online' : 'cash',
        'category': selectedCategory.value!.id,
      };

      if (descController.text.trim().isNotEmpty) {
        data['description'] = descController.text.trim();
      }
      String? isoDate = _isoDate;
      if (isoDate == null && dateController.text.trim().isNotEmpty) {
        final parsed = AppDateTime.tryParseDate(dateController.text);
        if (parsed != null) isoDate = AppDateTime.toIsoDate(parsed);
      }
      if (isoDate != null && isoDate.isNotEmpty) {
        data['date'] = isoDate;
      }
      if (startTimeController.text.trim().isNotEmpty) {
        data['startTime'] = AppDateTime.formatTime12h(startTimeController.text);
      }
      if (endTimeController.text.trim().isNotEmpty) {
        data['endTime'] = AppDateTime.formatTime12h(endTimeController.text);
      }
      data['address'] = addressController.text.trim();
      data['latitude'] = selectedLatitude.value;
      data['longitude'] = selectedLongitude.value;
      if (uploadedImageUrls.isNotEmpty) {
        data['images'] = uploadedImageUrls.toList();
      }

      final api = Get.find<ApiClient>();
      final response = await api.post(
        ApiConstants.jobs,
        data: data,
      );

      if (response.success) {
        final resData = response.data is Map ? response.data as Map<String, dynamic> : null;
        final checkoutUrl = resData?['checkoutUrl'] as String?;

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          final jobId = (resData?['_id'] ?? resData?['id'])?.toString() ?? '';
          // The server computed the total (rate × hours for hourly jobs): charge exactly that.
          final jobBudget = (resData?['budget'] as num?)?.toDouble() ??
              (_hourlyTotal?.toDouble() ?? double.tryParse(budgetController.text.trim()) ?? 0.0);
          final sessId = resData?['sessionId'] as String? ?? '';

          Get.toNamed(
            Routes.checkout,
            arguments: {
              'orderId': jobId,
              'orderType': 'job',
              'amount': jobBudget,
              'currency': 'MAD',
              'title': titleController.text.trim(),
              'sessionId': sessId,
              'metadata': {
                'userId': Get.find<AuthService>().currentUser.value?.id,
                'jobId': jobId,
              },
            },
          )?.then((paid) {
            if (paid == true) {
              // Land on Bookings so they see the job under Awaiting.
              Get.offAllNamed(Routes.home, arguments: {'tab': 1});
            } else {
              // Stay so the client can retry payment or edit the job
              AppFeedback.info('ui_job_saved_as_unpaid_complete_payment_from'.tr,
                  title: 'profile_payment'.tr);
            }
          });
          return;
        }

        AppFeedback.success('ui_job_posted_successfully'.tr, title: 'booking_success'.tr);
        Get.offAllNamed(Routes.home, arguments: {'tab': 1});
      } else {
        throw Exception(response.message ?? 'Failed to post job');
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (!isClosed) {
        isSubmitting.value = false;
      }
    }
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  Widget _buildPaymentOption(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final isDark = Get.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFF3F4F6))
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : Colors.grey[200]!),
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? (isDark ? AppColors.primary : Colors.black)
                      : (isDark ? AppColors.darkTextHint : Colors.grey[400]),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDark ? AppColors.darkTextPrimary : Colors.black)
                        : (isDark ? AppColors.darkTextSecondary : Colors.grey[400]),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            if (isSelected)
              const PositionedDirectional(
                end: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              )
            else
              PositionedDirectional(
                end: 0,
                top: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey[300]!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    _debounce?.cancel();
    budgetController.removeListener(_recomputeTotal);
    startTimeController.removeListener(_recomputeTotal);
    endTimeController.removeListener(_recomputeTotal);
    titleController.dispose();
    dateController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    descController.dispose();
    addressController.dispose();
    budgetController.dispose();
    super.onClose();
  }
}
