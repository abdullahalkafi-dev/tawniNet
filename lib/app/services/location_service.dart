import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';

class LocationService extends GetxService {
  late final ApiClient _api;

  final currentLatitude = RxnDouble();
  final currentLongitude = RxnDouble();
  final currentAddress = RxnString();

  // Mandatory GPS Observables for Helper mode
  final isGpsServiceEnabled = false.obs;
  final hasLocationPermission = false.obs;
  bool get isGpsReady => isGpsServiceEnabled.value && hasLocationPermission.value;

  Timer? _heartbeatTimer;
  String? _activeJobId;
  String? get activeJobId => _activeJobId;

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

  /// Starts 1-minute periodic location heartbeat over Socket.IO (Redis Geo backend)
  void startPeriodicHeartbeat({String? activeJobId}) {
    _activeJobId = activeJobId;
    _heartbeatTimer?.cancel();

    // Trigger immediately once
    _sendLocationPing();

    // Repeat every 60 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _sendLocationPing();
    });
  }

  void setActiveJobId(String? jobId) {
    _activeJobId = jobId;
  }

  void stopPeriodicHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _activeJobId = null;
  }

  Future<void> _sendLocationPing() async {
    try {
      final isServiceOn = await Geolocator.isLocationServiceEnabled();
      if (!isServiceOn) {
        isGpsServiceEnabled.value = false;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;

      if (Get.isRegistered<SocketService>()) {
        final socket = Get.find<SocketService>();
        if (socket.isConnected.value) {
          socket.emitHelperLocationPing({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
            'speed': position.speed,
            if (_activeJobId != null && _activeJobId!.isNotEmpty)
              'jobId': _activeJobId,
          });
        }
      }
    } catch (_) {
      // Best-effort ping; silent fail on transient GPS signal loss
    }
  }

  /// Reverse geocode: lat/lon → address string
  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lon) async {
    try {
      final response = await _api.get(
        ApiConstants.geocodingReverse,
        queryParameters: {'lat': lat, 'lon': lon},
      );
      if (response.success && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Forward geocode: search query → list of results
  Future<List<Map<String, dynamic>>> forwardGeocode(String query, {int limit = 5}) async {
    try {
      final response = await _api.get(
        ApiConstants.geocodingForward,
        queryParameters: {'q': query, 'limit': limit},
      );
      if (response.success && response.data != null) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Search places alias to forwardGeocode
  Future<List<Map<String, dynamic>>> searchPlaces(String query, {int limit = 5}) async {
    return forwardGeocode(query, limit: limit);
  }

  /// Get current GPS location and reverse geocode to address
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
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    stopPeriodicHeartbeat();
    super.onClose();
  }
}
