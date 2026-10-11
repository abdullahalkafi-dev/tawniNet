import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/location_service.dart';

class LocationPickResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String title;

  const LocationMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.title = 'Select Location',
  });

  static Future<LocationPickResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    String? initialAddress,
    String? title,
  }) {
    return Navigator.of(context).push<LocationPickResult>(
      MaterialPageRoute(
        builder: (_) => LocationMapPicker(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialAddress: initialAddress,
          title: title ?? 'select_location'.tr,
        ),
      ),
    );
  }

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  late final MapController _mapController;
  late LatLng _currentCenter;
  String _currentAddress = '';
  bool _isGeocoding = false;
  Timer? _debounceTimer;

  // Fallback default: Casablanca, Morocco
  static const LatLng _defaultCasablanca = LatLng(33.5731, -7.5898);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _currentCenter = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else if (Get.isRegistered<LocationService>()) {
      final loc = Get.find<LocationService>();
      if (loc.currentLatitude.value != null && loc.currentLongitude.value != null) {
        _currentCenter = LatLng(loc.currentLatitude.value!, loc.currentLongitude.value!);
      } else {
        _currentCenter = _defaultCasablanca;
      }
    } else {
      _currentCenter = _defaultCasablanca;
    }

    _currentAddress = widget.initialAddress ?? '';
    if (_currentAddress.isEmpty) {
      _reverseGeocode(_currentCenter);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _currentCenter = camera.center;
      });

      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocode(_currentCenter);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      if (Get.isRegistered<LocationService>()) {
        final loc = Get.find<LocationService>();
        final res = await loc.reverseGeocode(point.latitude, point.longitude);
        if (mounted && res != null) {
          final addr = (res['address'] ?? res['displayName'])?.toString() ?? '';
          if (addr.isNotEmpty) {
            setState(() {
              _currentAddress = addr;
            });
          }
        }
      }
    } catch (_) {
      // Best effort reverse geocode
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      if (Get.isRegistered<LocationService>()) {
        final loc = Get.find<LocationService>();
        final addr = await loc.getCurrentAddress();
        if (loc.currentLatitude.value != null && loc.currentLongitude.value != null) {
          final pos = LatLng(loc.currentLatitude.value!, loc.currentLongitude.value!);
          _mapController.move(pos, 16.0);
          setState(() {
            _currentCenter = pos;
            if (addr != null && addr.isNotEmpty) _currentAddress = addr;
          });
          if (addr == null || addr.isEmpty) {
            _reverseGeocode(pos);
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.awnneaapp',
                tileBuilder: isDark ? darkModeTileBuilder : null,
              ),
            ],
          ),

          // Stationary Center Pin with pulse shadow
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36), // anchor pin point at center
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.place,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Info Pill
          Positioned(
            top: 16,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'drag_map_to_set_location'.tr.isNotEmpty
                          ? 'drag_map_to_set_location'.tr
                          : 'Drag map to place the pin on exact address',
                      style: AppStyles.bodySmallOf(context).copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Floating Control Buttons
          Positioned(
            right: 16,
            top: 76,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.add,
                  tooltip: 'Zoom In',
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildFloatingButton(
                  icon: Icons.my_location,
                  tooltip: 'My Location',
                  color: AppColors.primary,
                  iconColor: Colors.white,
                  onTap: _goToMyLocation,
                ),
              ],
            ),
          ),

          // Bottom Address Sheet & Confirm Button
          Positioned(
            bottom: 16 + bottomInset,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Location',
                              style: AppStyles.bodySmall.copyWith(
                                color: context.textHintColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_isGeocoding)
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Detecting address...',
                                    style: AppStyles.bodyMediumOf(context).copyWith(fontSize: 13),
                                  ),
                                ],
                              )
                            else
                              Text(
                                _currentAddress.isNotEmpty
                                    ? _currentAddress
                                    : '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}',
                                style: AppStyles.bodyMediumOf(context).copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final addr = _currentAddress.isNotEmpty
                            ? _currentAddress
                            : '${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}';
                        Navigator.of(context).pop(
                          LocationPickResult(
                            latitude: _currentCenter.latitude,
                            longitude: _currentCenter.longitude,
                            address: addr,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'confirm_location'.tr.isNotEmpty ? 'confirm_location'.tr : 'Confirm Location',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color ?? (context.isDarkMode ? AppColors.darkCard : Colors.white),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: iconColor ?? context.textPrimaryColor),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
