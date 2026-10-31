import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';

/// Why a place search / reverse lookup failed (so the screen can say it).
class GeocodeException implements Exception {
  final String message;
  final bool isRateLimited;
  GeocodeException(this.message, {this.isRateLimited = false});
  @override
  String toString() => message;
}

class LocationService extends GetxService {
  late final ApiClient _api;

  final currentLatitude = RxnDouble();
  final currentLongitude = RxnDouble();
  final currentAddress = RxnString();

  // GPS state (the helper needs it only for the job he is working on)
  final isGpsServiceEnabled = false.obs;
  final hasLocationPermission = false.obs;
  bool get isGpsReady => isGpsServiceEnabled.value && hasLocationPermission.value;

  /// The helper's position is being shared for this job.
  final trackingJobId = RxnString();
  bool get isTracking => trackingJobId.value != null;

  StreamSubscription<Position>? _trackSub;
  DateTime? _lastSent;
  DateTime? _lastOneShot;

  /// While travelling a position goes out at most this often (live tracking
  /// needs fresh points; a faster rate only drains the battery).
  static const _trackInterval = Duration(seconds: 10);

  Future<LocationService> init() async {
    _api = Get.find<ApiClient>();
    try {
      await checkGpsStatus().timeout(const Duration(seconds: 2));
    } catch (_) {}
    return this;
  }

  /// Verifies both hardware GPS switch and app location permissions
  Future<bool> checkGpsStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      isGpsServiceEnabled.value = serviceEnabled;

      final permission = await Geolocator.checkPermission();
      hasLocationPermission.value =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      return isGpsReady;
    } catch (_) {
      isGpsServiceEnabled.value = false;
      hasLocationPermission.value = false;
      return false;
    }
  }

  /// Interactive resolution: prompts permission or opens device location settings
  Future<bool> requestGpsAndPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }

      return await checkGpsStatus();
    } catch (_) {
      return false;
    }
  }

  // ─── Sharing the helper's position (only while working on a job) ──────

  /// The helper is travelling to a job: share the position with the client.
  /// Runs as a visible foreground service on Android and as a background
  /// location session on iOS, so it keeps working when the screen is off or a
  /// maps app is in front. Stops by itself when [stopJobTracking] is called
  /// (arrived / job cancelled / completed).
  Future<void> startJobTracking(String jobId) async {
    if (jobId.isEmpty) return;
    if (trackingJobId.value == jobId && _trackSub != null) return;
    stopJobTracking();

    final ready = await checkGpsStatus();
    if (!ready) {
      // Do not interrupt the helper here; the job screen explains what is missing.
      return;
    }
    trackingJobId.value = jobId;
    _lastSent = null;

    final LocationSettings settings;
    if (!kIsWeb && Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: _trackInterval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'tracking_notification_title'.tr,
          notificationText: 'tracking_notification_text'.tr,
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (!kIsWeb && Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 15,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15);
    }

    try {
      _trackSub = Geolocator.getPositionStream(locationSettings: settings).listen(
        _onTrackedPosition,
        onError: (Object e) {
          if (kDebugMode) debugPrint('[Location] tracking error: $e');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Location] could not start tracking: $e');
      trackingJobId.value = null;
    }
  }

  void stopJobTracking() {
    _trackSub?.cancel();
    _trackSub = null;
    trackingJobId.value = null;
  }

  void _onTrackedPosition(Position position) {
    currentLatitude.value = position.latitude;
    currentLongitude.value = position.longitude;

    final now = DateTime.now();
    if (_lastSent != null && now.difference(_lastSent!) < _trackInterval) return;
    _lastSent = now;
    _emit(position, jobId: trackingJobId.value);
  }

  void _emit(Position position, {String? jobId}) {
    if (!Get.isRegistered<SocketService>()) return;
    final socket = Get.find<SocketService>();
    if (!socket.isConnected.value) return;
    socket.emitHelperLocationPing({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': position.heading,
      'speed': position.speed,
      if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
    });
  }

  /// One position update when an available helper opens the app, so job
  /// matching knows roughly where they are today. No continuous sharing.
  Future<void> refreshPositionOnce() async {
    final now = DateTime.now();
    if (_lastOneShot != null && now.difference(_lastOneShot!) < const Duration(minutes: 10)) {
      return;
    }
    _lastOneShot = now;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;
      _emit(position);
    } catch (_) {
      // best effort
    }
  }

  // ─── Geocoding (through the backend) ──────────────────────────────

  GeocodeException _geocodeError(Object e) {
    if (e is ApiException) {
      return GeocodeException(e.displayMessage, isRateLimited: e.statusCode == 429);
    }
    return GeocodeException('err_http_unknown'.tr);
  }

  /// Reverse geocode: lat/lon → address string. Null when nothing was found;
  /// throws [GeocodeException] when the service itself failed.
  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lon) async {
    try {
      final response = await _api.get(
        ApiConstants.geocodingReverse,
        queryParameters: {'lat': lat, 'lon': lon, 'lang': Get.locale?.languageCode ?? 'fr'},
      );
      if (response.success && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      throw _geocodeError(e);
    }
  }

  /// Forward geocode: search query → list of results. Throws [GeocodeException] on failure.
  Future<List<Map<String, dynamic>>> forwardGeocode(String query, {int limit = 5}) async {
    try {
      final response = await _api.get(
        ApiConstants.geocodingForward,
        queryParameters: {
          'q': query,
          'limit': limit,
          'lang': Get.locale?.languageCode ?? 'fr',
          if (currentLatitude.value != null && currentLongitude.value != null) ...{
            'lat': currentLatitude.value,
            'lon': currentLongitude.value,
          },
        },
      );
      final data = response.data;
      if (response.success && data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      throw _geocodeError(e);
    }
  }

  /// Search places alias to forwardGeocode
  Future<List<Map<String, dynamic>>> searchPlaces(String query, {int limit = 5}) async {
    return forwardGeocode(query, limit: limit);
  }

  /// Get current GPS location and reverse geocode to address. Null when the
  /// position or the address could not be determined.
  Future<String?> getCurrentAddress() async {
    try {
      final ready = await checkGpsStatus();
      if (!ready) {
        final granted = await requestGpsAndPermission();
        if (!granted) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;

      final result = await reverseGeocode(position.latitude, position.longitude);
      final address = result?['address'] as String?;
      if (address != null && address.isNotEmpty) {
        currentAddress.value = address;
        return address;
      }
      return null;
    } on GeocodeException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    stopJobTracking();
    super.onClose();
  }
}
