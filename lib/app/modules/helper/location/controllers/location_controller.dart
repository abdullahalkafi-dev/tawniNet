import 'dart:async';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/services/location_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/utils/app_snackbar.dart';

class LocationController extends GetxController {
  final searchQuery = ''.obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isGettingLocation = false.obs;
  final isSearching = false.obs;

  Timer? _debounce;

  String get _destinationRoute {
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;

      if (user?.role == 'helper') {
        if (user?.isHelperFormSubmitted != true) {
          return Routes.applyAsHelper;
        }

        switch (user?.helperApplicationStatus) {
          case 'approved':
            return Routes.helperHome;
          case 'pending_appeal':
            return Routes.applicationPending;
          case 'rejected':
            return Routes.applicationRejected;
          case 'pending':
          default:
            if (user?.diditStatus == 'In Review') {
              return Routes.applicationPending;
            }
            return Routes.helperKycVerification;
        }
      }
      return Routes.home;
    } catch (_) {
      return Routes.home;
    }
  }

  // ─── Allow Location (GPS Auto-Detect) ───────────────────

  Future<void> onAllowLocation() async {
    if (isGettingLocation.value) return;
    isGettingLocation.value = true;

    try {
      // 1. Check if GPS / Location services are enabled on device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationNotice(
          'Location services (GPS) are turned off. Please enable GPS in device settings to proceed.',
          isLocationOff: true,
        );
        return;
      }

      // 2. Check Permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationNotice(
          'Location permission is required to find helpers or jobs near you.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationNotice(
          'Location permission is permanently denied. Please enable location permissions in App Settings.',
          openAppSettings: true,
        );
        return;
      }

      // 3. Obtain Position with High Accuracy
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      // 4. Best-effort reverse geocode address
      String? address;
      try {
        final locationService = Get.find<LocationService>();
        final result = await locationService.reverseGeocode(
          position.latitude,
          position.longitude,
        );
        address = result?['address'] as String?;
      } catch (_) {
        // Geocoding failed — proceed with coordinates
      }

      // 5. Save verified location to backend
      await _saveLocation(
        longitude: position.longitude,
        latitude: position.latitude,
        address: address,
      );

      // 6. Refresh user state so downstream screens have active location
      try {
        final authService = Get.find<AuthService>();
        await authService.getMe();
      } catch (_) {}

      // 7. Successfully advance to destination route
      _navigateToDestination();
    } catch (e) {
      _showLocationNotice(
        'Could not detect your GPS location. Please check your signal or choose "Enter Location Manually" below.',
      );
    } finally {
      if (!isClosed) {
        isGettingLocation.value = false;
      }
    }
  }

  void _showLocationNotice(
    String message, {
    bool isLocationOff = false,
    bool openAppSettings = false,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      titleText: const Text(
        'Location Required',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.3,
        ),
      ),
      icon: const Icon(
        Icons.location_off_rounded,
        color: Colors.white,
        size: 26,
      ),
      mainButton: (isLocationOff || openAppSettings)
          ? TextButton(
              onPressed: () async {
                Get.closeCurrentSnackbar();
                if (isLocationOff) {
                  await Geolocator.openLocationSettings();
                } else if (openAppSettings) {
                  await Geolocator.openAppSettings();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          : null,
      backgroundColor: const Color(0xFFE53935),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 5),
    );
  }

  // ─── Manual Location ────────────────────────────────────

  void onEnterManually() {
    Get.toNamed(Routes.manualLocation);
  }

  void onUseCurrentLocation() {
    onAllowLocation();
  }

  void searchLocation(String query) {
    searchQuery.value = query;
    _debounce?.cancel();

    if (query.trim().length < 3) {
      searchResults.clear();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (isClosed) return;
      isSearching.value = true;
      try {
        final locationService = Get.find<LocationService>();
        final results = await locationService.forwardGeocode(query);
        if (!isClosed) {
          searchResults.assignAll(results);
        }
      } catch (_) {
        if (!isClosed) {
          searchResults.clear();
        }
      } finally {
        if (!isClosed) {
          isSearching.value = false;
        }
      }
    });
  }

  void selectLocation(Map<String, dynamic> result) async {
    final lat = (result['lat'] as num?)?.toDouble();
    final lon = (result['lon'] as num?)?.toDouble();
    final address = result['displayName'] as String?;

    if (lat == null || lon == null) {
      _showError('Could not obtain coordinates for this location.');
      return;
    }

    try {
      await _saveLocation(
        longitude: lon,
        latitude: lat,
        address: address,
      );

      // Refresh user profile
      try {
        final authService = Get.find<AuthService>();
        await authService.getMe();
      } catch (_) {}

      _navigateToDestination();
    } catch (e) {
      _showError(e);
    }
  }

  void goBack() {
    Get.back();
  }

  // ─── Helpers ────────────────────────────────────────────

  Future<void> _saveLocation({
    required double longitude,
    required double latitude,
    String? address,
  }) async {
    final api = Get.find<ApiClient>();
    await api.patch(
      ApiConstants.userLocation,
      data: {
        'longitude': longitude,
        'latitude': latitude,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
  }

  void _navigateToDestination() {
    if (isClosed) return;
    Get.offAllNamed(_destinationRoute);
  }

  void _showError(dynamic message) {
    AppSnackbar.showError(message);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
