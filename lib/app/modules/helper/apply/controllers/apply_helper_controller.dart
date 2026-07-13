import 'dart:io';
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

class ApplyHelperController extends GetxController {
  late final ApiClient _api;
  final _picker = ImagePicker();

  // Text controllers
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final cityController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final priceController = TextEditingController();
  final experienceController = TextEditingController();
  final serviceRadiusController = TextEditingController();
  final bioController = TextEditingController();

  // Dropdown state
  final selectedLanguage = 'English'.obs;
  final selectedServiceType = Rxn<Category>();
  final selectedIdType = 'NID'.obs;

  // Upload state
  final profilePhotoPath = RxnString();
  final profilePhotoKey = RxnString();
  final selectedPhotoPaths = <String>[].obs;
  final uploadedPhotoKeys = <String>[].obs;
  final documentPath = RxnString();
  final documentKey = RxnString();
  final documentFileName = RxnString();
  final documentFileSize = RxnString();

  // Loading states
  final isLoading = false.obs;
  final isLoadingCategories = false.obs;
  final isUploadingPhoto = false.obs;
  final isUploadingDocument = false.obs;

  // Options
  final languages = ['English', 'Moroccan Arabic'].obs;
  final idTypes = ['NID', 'Passport', 'Driving License', 'Residence Permit'].obs;
  final categories = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiClient>();
    _loadUserProfile();
    fetchCategories();
  }

  void _loadUserProfile() {
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      if (user != null) {
        fullNameController.text = user.name;
        emailController.text = user.email ?? '';
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
      // Fallback categories with mock IDs
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
      }
    } catch (e) {
      _showError('Failed to pick image');
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
        if (selectedPhotoPaths.length >= 5) {
          _showError('Maximum 5 photos allowed');
          break;
        }
        selectedPhotoPaths.add(image.path);
        // Upload in background
        _uploadPhotoInBackground(image.path);
      }
    } catch (e) {
      _showError('Failed to pick images');
    }
  }

  Future<void> _uploadPhotoInBackground(String path) async {
    final key = await _uploadFile(path, 'image');
    if (key != null) {
      uploadedPhotoKeys.add(key);
    }
  }

  void removePhoto(int index) {
    if (index < selectedPhotoPaths.length) {
      selectedPhotoPaths.removeAt(index);
    }
    if (index < uploadedPhotoKeys.length) {
      uploadedPhotoKeys.removeAt(index);
    }
  }

  // ─── Document ───────────────────────────────────────────

  Future<void> pickDocument() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );
      if (file == null) return;

      documentPath.value = file.path;
      documentFileName.value = file.name;

      // Get file size
      final size = await File(file.path).length();
      documentFileSize.value = _formatFileSize(size);

      // Upload immediately
      final key = await _uploadFile(file.path, 'document');
      if (key != null) {
        documentKey.value = key;
      }
    } catch (e) {
      _showError('Failed to pick document');
    }
  }

  void removeDocument() {
    documentPath.value = null;
    documentKey.value = null;
    documentFileName.value = null;
    documentFileSize.value = null;
  }

  // ─── Upload Helper ──────────────────────────────────────

  Future<String?> _uploadFile(String filePath, String type) async {
    try {
      final file = File(filePath);
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ─── Submit Application ─────────────────────────────────

  Future<void> submitApplication() async {
    if (ageController.text.isEmpty) {
      _showError('Please enter your age');
      return;
    }
    if (cityController.text.isEmpty) {
      _showError('Please enter your city');
      return;
    }
    if (selectedServiceType.value == null) {
      _showError('Please select a service type');
      return;
    }
    if (priceController.text.isEmpty) {
      _showError('Please enter your price per hour');
      return;
    }
    if (serviceRadiusController.text.isEmpty) {
      _showError('Please enter your service radius');
      return;
    }

    isLoading.value = true;
    try {
      final response = await _api.post(
        ApiConstants.helperApply,
        data: {
          'age': int.tryParse(ageController.text) ?? 0,
          'city': cityController.text.trim(),
          'language': selectedLanguage.value,
          'serviceType': selectedServiceType.value!.id,
          'pricePerHour': double.tryParse(priceController.text) ?? 0,
          'experience': int.tryParse(experienceController.text) ?? 0,
          'serviceRadius': double.tryParse(serviceRadiusController.text) ?? 0,
          'documentType': selectedIdType.value.toLowerCase().replaceAll(' ', '_'),
          'documentUrl': documentKey.value ?? 'placeholder/document',
          'profilePhotos': uploadedPhotoKeys.toList(),
          if (profilePhotoKey.value != null)
            'avatar': profilePhotoKey.value,
          if (phoneController.text.isNotEmpty)
            'phone': phoneController.text.trim(),
        },
      );

      if (isClosed) return;

      if (response.success) {
        final authService = Get.find<AuthService>();
        await authService.getMe();

        if (isClosed) return;
        Get.offAllNamed(Routes.applicationPending);
      } else {
        throw Exception(response.message ?? 'Application failed');
      }
    } catch (e) {
      if (isClosed) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (!isClosed) {
        isLoading.value = false;
      }
    }
  }

  // ─── Other ──────────────────────────────────────────────

  void updateAndReapply() {
    Get.back();
  }

  void logout() async {
    final authService = Get.find<AuthService>();
    await authService.logout();
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    ageController.dispose();
    cityController.dispose();
    phoneController.dispose();
    emailController.dispose();
    priceController.dispose();
    experienceController.dispose();
    serviceRadiusController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
