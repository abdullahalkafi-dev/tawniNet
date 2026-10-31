import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/core/values/app_colors.dart';
import 'package:awnneaapp/app/data/models/booking_model.dart';

/// Colored label for a job status, the same on every screen (client and helper).
class JobStatusBadge extends StatelessWidget {
  final BookingStatus status;

  /// The helper said the work is finished and the client still has to confirm.
  final bool waitingConfirmation;

  const JobStatusBadge({super.key, required this.status, this.waitingConfirmation = false});

  static (String, Color) describe(BookingStatus status, {bool waitingConfirmation = false}) {
    if (waitingConfirmation) {
      return ('job_status_waiting_confirm'.tr, Colors.deepPurple);
    }
    switch (status) {
      case BookingStatus.pendingPayment:
        return ('booking_unpaid'.tr, Colors.orange.shade700);
      case BookingStatus.open:
        return ('ui_looking_for_helper_2'.tr, Colors.blueGrey);
      case BookingStatus.inProgress:
        return ('job_status_assigned'.tr, Colors.blue);
      case BookingStatus.onTheWay:
        return ('job_status_on_the_way'.tr, AppColors.primary);
      case BookingStatus.arrived:
        return ('job_status_arrived'.tr, const Color(0xFF0D9488));
      case BookingStatus.completed:
        return ('booking_completed'.tr, const Color(0xFF0F766E));
      case BookingStatus.cancelled:
        return ('booking_cancelled'.tr, Colors.orange);
      case BookingStatus.unknown:
        return ('job_status_unknown'.tr, Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (text, color) = describe(status, waitingConfirmation: waitingConfirmation);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
