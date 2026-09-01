import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/api_client.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';

class LocationService extends GetxService {
  late final ApiClient _api;

  final currentLatitude = RxnDouble();
  final currentLongitude = RxnDouble();
  final currentAddress = RxnString();

  Future<LocationService> init() async {
    _api = Get.find<ApiClient>();
    return this;
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
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
}

