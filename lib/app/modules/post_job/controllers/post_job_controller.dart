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
  final isSubmitting = false.obs;

  final _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    _initUserAddress();
  }

  void _initUserAddress() {
    try {
      final user = Get.find<AuthService>().currentUser.value;
      if (user != null && user.address != null && user.address!.isNotEmpty) {
        addressController.text = user.address!;
        selectedLatitude.value = user.latitude;
        selectedLongitude.value = user.longitude;
      }
    } catch (_) {}
  }

  // ─── Categories ─────────────────────────────────────────

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final categoryService = Get.find<CategoryService>();
      final result = await categoryService.getActiveCategories();
      categories.assignAll(result);
    } catch (e) {
      // Fallback to mock categories if API fails
      categories.assignAll([
        Category(id: 'mock_1', name: 'Cleaning Service', icon: Icons.home_repair_service_outlined, color: Colors.yellow),
        Category(id: 'mock_2', name: 'Shifting Service', icon: Icons.local_shipping_outlined, color: Colors.amber),
        Category(id: 'mock_3', name: 'Electrician Service', icon: Icons.bolt, color: Colors.purple),
        Category(id: 'mock_4', name: 'Plumber Service', icon: Icons.plumbing, color: Colors.blue),
        Category(id: 'mock_5', name: 'Painting Service', icon: Icons.format_paint, color: Colors.deepOrange),
        Category(id: 'mock_6', name: 'Moving', icon: Icons.directions_bus_outlined, color: Colors.blue),
        Category(id: 'mock_7', name: 'Garden', icon: Icons.opacity_outlined, color: Colors.orangeAccent),
        Category(id: 'mock_8', name: 'Mechanic Service', icon: Icons.build, color: Colors.brown),
        Category(id: 'mock_9', name: 'Laundry', icon: Icons.local_laundry_service, color: Colors.cyan),
        Category(id: 'mock_10', name: 'Others', icon: Icons.help_outline, color: Colors.grey),
      ]);
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
    selectedLatitude.value = lat;
    selectedLongitude.value = lng;
    addressSuggestions.clear();
  }

  Future<void> useCurrentLocation() async {
    try {
      final locService = Get.find<LocationService>();
      final address = await locService.getCurrentAddress();
      if (address != null && address.isNotEmpty) {
        addressController.text = address;
        selectedLatitude.value = locService.currentLatitude.value;
        selectedLongitude.value = locService.currentLongitude.value;
        addressSuggestions.clear();
      } else {
        Get.snackbar(
          'Location',
          'Could not determine current address',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (_) {}
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
        'Maximum $kJobMaxImages images allowed',
        title: 'Limit reached',
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
          'Only $kJobMaxImages images allowed. $skipped image(s) were not added.',
          title: 'Limit reached',
        );
      }
    } catch (e) {
      _showError('Failed to pick images');
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
            ? 'Failed to upload images. Please try again.'
            : 'Failed to upload $failed of ${selectedImages.length} image(s). '
                'Remove failed photos or retry.',
      );
    }

    return urls;
  }

  // ─── Submit Job ─────────────────────────────────────────

  void postJob() {
    // Validate required fields
    if (titleController.text.trim().isEmpty) {
      _showError('Please enter a job title');
      return;
    }
    if (budgetController.text.trim().isEmpty) {
      _showError('Please enter a budget');
      return;
    }
    if (selectedCategory.value == null) {
      _showError('Please select a category');
      return;
    }

    String? isoDate = _isoDate;
    if (isoDate == null && dateController.text.trim().isNotEmpty) {
      final parsed = AppDateTime.tryParseDate(dateController.text);
      if (parsed != null) isoDate = AppDateTime.toIsoDate(parsed);
    }
    if (isoDate == null || isoDate.isEmpty) {
      _showError('Please select a preferred date');
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
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _buildPaymentOption(
                        'Online Payment',
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
                        'Cash',
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
                        'Cancel',
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
                      child: const Text(
                        'Continue',
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
      if (addressController.text.trim().isNotEmpty) {
        data['address'] = addressController.text.trim();
      }
      if (selectedLatitude.value != null) {
        data['latitude'] = selectedLatitude.value;
      }
      if (selectedLongitude.value != null) {
        data['longitude'] = selectedLongitude.value;
      }
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
          final jobBudget = double.tryParse(budgetController.text.trim()) ?? 0.0;
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
              Get.snackbar(
                'Payment',
                'Job saved as unpaid. Complete payment from My Bookings.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.orange.shade100,
                colorText: Colors.orange.shade900,
                margin: const EdgeInsets.all(16),
              );
            }
          });
          return;
        }

        Get.snackbar(
          'Success',
          'Job posted successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          margin: const EdgeInsets.all(16),
        );
        Get.offAllNamed(Routes.home);
      } else {
        throw Exception(response.message ?? 'Failed to post job');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
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
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
              )
            else
              Positioned(
                right: 0,
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
