import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awnneaapp/app/core/constants/map_config.dart';
import 'package:awnneaapp/app/core/widgets/app_network_image.dart';
import 'package:awnneaapp/app/core/utils/app_feedback.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:awnneaapp/app/services/socket_service.dart';
import 'package:awnneaapp/app/modules/messages/controllers/messages_controller.dart';

class LiveTrackingView extends StatefulWidget {
  const LiveTrackingView({super.key});

  @override
  State<LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<LiveTrackingView> {
  late final MapController _mapController;
  StreamSubscription? _trackingSubscription;

  late final String jobId;
  late final String jobTitle;
  late final String address;
  late final String workerUserId;
  late final String workerName;
  late final String workerImage;
  late final String category;
  late final LatLng destinationPoint;

  /// The job has no coordinates (should not happen once the job is accepted): no map is shown.
  late final bool hasDestination;

  LatLng? helperPoint;
  DateTime? lastPingTime;
  bool _hasUserInteracted = false;
  StreamSubscription? _endedSubscription;
  Timer? _staleTimer;

  static const _distance = Distance();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};

    jobId = args['jobId']?.toString() ?? '';
    jobTitle = args['jobTitle']?.toString() ?? 'tracking_title'.tr;
    address = args['address']?.toString() ?? '';
    workerUserId = args['workerUserId']?.toString() ?? '';
    workerName = args['workerName']?.toString() ?? '';
    workerImage = args['workerImage']?.toString() ?? '';
    category = args['category']?.toString() ?? '';

    final destLat = (args['latitude'] as num?)?.toDouble();
    final destLon = (args['longitude'] as num?)?.toDouble();
    hasDestination = destLat != null && destLon != null;
    destinationPoint = LatLng(destLat ?? 0, destLon ?? 0);

    final initHelperLat = (args['helperLat'] as num?)?.toDouble();
    final initHelperLon = (args['helperLon'] as num?)?.toDouble();
    if (initHelperLat != null && initHelperLon != null) {
      helperPoint = LatLng(initHelperLat, initHelperLon);
    }

    _subscribeToLiveTracking();
    // Re-evaluate "last seen" every 15 s so a silent helper is flagged.
    _staleTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitCameraToBounds();
    });
  }

  /// Whole minutes since the last position, or null if none arrived yet.
  int? get _minutesSinceLastPing =>
      lastPingTime == null ? null : DateTime.now().difference(lastPingTime!).inMinutes;

  bool get _isStale => (_minutesSinceLastPing ?? 0) >= 2;

  /// Straight-line distance and a rough arrival time (about 25 km/h in town).
  (String, String)? get _distanceAndEta {
    final h = helperPoint;
    if (h == null || !hasDestination) return null;
    final meters = _distance(h, destinationPoint);
    final km = meters / 1000;
    final label = km < 1 ? '${meters.round()} m' : '${km.toStringAsFixed(1)} km';
    final minutes = (km / 25 * 60).ceil().clamp(1, 600);
    return (label, 'tracking_eta_minutes'.trParams({'n': '$minutes'}));
  }

  void _subscribeToLiveTracking() {
    if (jobId.isEmpty) return;

    if (Get.isRegistered<SocketService>()) {
      final socketService = Get.find<SocketService>();
      socketService.joinTracking(jobId);

      _trackingSubscription = socketService.onTrackingLocationUpdate.listen((data) {
        if (!mounted) return;
        final updateJobId = data['jobId']?.toString();
        if (updateJobId == jobId || updateJobId == null || updateJobId.isEmpty) {
          final lat = (data['latitude'] as num?)?.toDouble();
          final lon = (data['longitude'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            final isFirstPoint = helperPoint == null;
            final stamp = (data['updatedAt'] as num?)?.toInt();
            setState(() {
              helperPoint = LatLng(lat, lon);
              lastPingTime = stamp != null
                  ? DateTime.fromMillisecondsSinceEpoch(stamp)
                  : DateTime.now();
            });
            if (isFirstPoint && !_hasUserInteracted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fitCameraToBounds();
              });
            }
          }
        }
      });

      // The helper arrived / the job ended: tracking stops.
      _endedSubscription = socketService.onTrackingEnded.listen((data) {
        if (!mounted) return;
        if (data['jobId']?.toString() != jobId) return;
        AppFeedback.info('tracking_ended'.tr);
        Get.back();
      });
    }
  }

  void _fitCameraToBounds() {
    if (!mounted || !hasDestination) return;
    try {
      if (helperPoint != null) {
        final dLat = (helperPoint!.latitude - destinationPoint.latitude).abs();
        final dLon = (helperPoint!.longitude - destinationPoint.longitude).abs();
        if (dLat < 0.0005 && dLon < 0.0005) {
          _mapController.move(destinationPoint, 16.5);
          return;
        }
        final bounds = LatLngBounds.fromPoints([helperPoint!, destinationPoint]);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(50, 100, 50, 240),
            maxZoom: 17.0,
          ),
        );
      } else {
        _mapController.move(destinationPoint, 15.0);
      }
    } catch (_) {}
  }


  Future<void> _openExternalNavigation(double lat, double lon, String title) async {
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
    );
    try {
      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon($title)');
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _endedSubscription?.cancel();
    _staleTimer?.cancel();
    if (Get.isRegistered<SocketService>() && jobId.isNotEmpty) {
      Get.find<SocketService>().leaveTracking(jobId);
    }
    super.dispose();
  }

  Future<void> _openChatWithHelper() async {
    if (workerUserId.isEmpty) return;
    try {
      if (Get.isRegistered<MessagesController>()) {
        final messagesController = Get.find<MessagesController>();
        final conversation = await messagesController.startConversation(workerUserId);
        if (conversation != null) {
          Get.toNamed(
            Routes.chatDetail,
            arguments: ChatSummary(
              id: conversation.id,
              name: workerName.isNotEmpty ? workerName : 'ui_helper'.tr,
              image: workerImage,
              otherUserId: workerUserId,
            ),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!hasDestination) {
      return Scaffold(
        appBar: AppBar(
          title: Text(jobTitle, style: AppStyles.h2Of(context).copyWith(fontSize: 18)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'tracking_no_location'.tr,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(color: context.textHintColor),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          jobTitle,
          style: AppStyles.h2Of(context).copyWith(fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          // OpenStreetMap / CartoDB Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: helperPoint ?? destinationPoint,
              initialZoom: 14.5,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  _hasUserInteracted = true;
                }
              },
            ),
            children: [
              MapConfig.tileLayer(dark: isDark),
              // Dashed line between Helper and Destination
              if (helperPoint != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [helperPoint!, destinationPoint],
                      color: AppColors.primary.withValues(alpha: 0.65),
                      strokeWidth: 3.5,
                      pattern: StrokePattern.dashed(segments: const [8, 6]),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Destination Pin
                  Marker(
                    point: destinationPoint,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 46,
                    ),
                  ),
                  // Live Helper Pin
                  if (helperPoint != null)
                    Marker(
                      point: helperPoint!,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.handyman_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Status Pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: helperPoint == null
                          ? Colors.amber
                          : _isStale
                              ? Colors.orange
                              : const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      helperPoint == null
                          ? 'tracking_gps_connecting'.tr
                          : _isStale
                              ? 'tracking_last_seen'.trParams({'n': '${_minutesSinceLastPing ?? 0}'})
                              : 'tracking_gps_active'.tr,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (_distanceAndEta != null)
                    Text(
                      '${_distanceAndEta!.$1} · ${_distanceAndEta!.$2}',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Floating Map Action Buttons (Right Side)
          PositionedDirectional(
            end: 16,
            top: 80,
            child: Column(
              children: [
                _buildFloatingMapButton(
                  icon: Icons.add,
                  tooltip: 'tracking_zoom_in'.tr,
                  onTap: () {
                    _hasUserInteracted = true;
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildFloatingMapButton(
                  icon: Icons.remove,
                  tooltip: 'tracking_zoom_out'.tr,
                  onTap: () {
                    _hasUserInteracted = true;
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildFloatingMapButton(
                  icon: Icons.fit_screen_rounded,
                  tooltip: 'tracking_fit_both'.tr,
                  onTap: _fitCameraToBounds,
                  color: AppColors.primary,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 8),
                if (helperPoint != null) ...[
                  _buildFloatingMapButton(
                    icon: Icons.my_location,
                    tooltip: 'tracking_center_helper'.tr,
                    onTap: () {
                      _hasUserInteracted = true;
                      _mapController.move(helperPoint!, 15.5);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                _buildFloatingMapButton(
                  icon: Icons.flag_outlined,
                  tooltip: 'tracking_center_destination'.tr,
                  onTap: () {
                    _hasUserInteracted = true;
                    _mapController.move(destinationPoint, 15.0);
                  },
                ),
              ],
            ),
          ),

          // Bottom Details & Action Sheet
          Positioned(
            bottom: 16 + bottomInset,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Helper Profile Row
                  if (workerName.isNotEmpty) ...[
                    Row(
                      children: [
                        AppAvatar(url: workerImage, name: workerName, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workerName,
                                style: AppStyles.h2Of(context).copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (category.isNotEmpty)
                                Text(
                                  category,
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (workerUserId.isNotEmpty)
                          SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: _openChatWithHelper,
                              icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                              label: Text(
                                'tracking_chat'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],

                  // Destination Address Row + External Directions Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.isNotEmpty ? address : 'tracking_customer_address'.tr,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (lastPingTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${'tracking_last_ping'.tr} ${lastPingTime!.hour.toString().padLeft(2, '0')}:${lastPingTime!.minute.toString().padLeft(2, '0')}:${lastPingTime!.second.toString().padLeft(2, '0')}',
                                  style: AppStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: context.textHintColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'tracking_open_directions'.tr,
                        icon: const Icon(Icons.directions, color: AppColors.primary),
                        onPressed: () => _openExternalNavigation(
                          destinationPoint.latitude,
                          destinationPoint.longitude,
                          address,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return Container(
      width: 42,
      height: 42,
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
