import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/core/values/app_styles.dart';
import 'package:awnneaapp/app/services/location_service.dart';

class GpsRequiredBarrier extends StatefulWidget {
  final VoidCallback? onGpsEnabled;

  const GpsRequiredBarrier({
    super.key,
    this.onGpsEnabled,
  });

  @override
  State<GpsRequiredBarrier> createState() => _GpsRequiredBarrierState();
}

class _GpsRequiredBarrierState extends State<GpsRequiredBarrier> {
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      if (Get.isRegistered<LocationService>()) {
        final loc = Get.find<LocationService>();
        final ready = await loc.checkGpsStatus();
        if (ready && mounted) {
          widget.onGpsEnabled?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Get.find<LocationService>();

    return Container(
      color: context.isDarkMode ? AppColors.darkBackground : AppColors.background,
      child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'gps_barrier_title'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.h2Of(context).copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'gps_barrier_desc'.tr,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMedium.copyWith(
                    height: 1.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ready = await locationService.requestGpsAndPermission();
                      if (ready && widget.onGpsEnabled != null) {
                        widget.onGpsEnabled!();
                      }
                    },
                    icon: const Icon(Icons.my_location, color: Colors.white, size: 20),
                    label: Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'gps_barrier_enable_btn'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final ready = await locationService.checkGpsStatus();
                    if (ready && widget.onGpsEnabled != null) {
                      widget.onGpsEnabled!();
                    }
                  },
                  child: Text(
                    'gps_barrier_already_enabled'.tr,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
