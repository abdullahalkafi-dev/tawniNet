import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:get/get.dart';

/// Helpers for flattening job API maps into display-safe strings.
class JobDisplay {
  JobDisplay._();

  /// Text address only. Never surface raw lat/lng or GeoJSON.
  static String safeLocation(Map job) {
    final address = job['address']?.toString() ?? '';
    if (address.isNotEmpty && address != 'null') return address;
    final city = job['city']?.toString() ?? '';
    if (city.isNotEmpty && city != 'null') return city;
    return 'ui_not_provided'.tr;
  }

  /// Street + area only (first 2 comma parts). Extra details belong in chat.
  static String publicAddress(Map job) {
    final address = job['address']?.toString() ?? '';
    if (address.isNotEmpty && address != 'null') {
      final parts =
          address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return 'ui_not_provided'.tr;
      if (parts.length == 1) return parts.first;
      return '${parts[0]}, ${parts[1]}';
    }
    final city = job['city']?.toString() ?? '';
    if (city.isNotEmpty && city != 'null') return city;
    return 'ui_not_provided'.tr;
  }

  static String safeText(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value.isEmpty || value == 'null' ? fallback : value;
    if (value is Map || value is List) return fallback;
    return value.toString();
  }

  static String personName(dynamic postedBy, {String fallback = ''}) {
    if (postedBy is Map) {
      return safeText(postedBy['name'], fallback: fallback);
    }
    return fallback;
  }

  static String personAvatar(dynamic postedBy, {String fallback = ''}) {
    if (postedBy is Map) {
      return safeText(postedBy['avatar'], fallback: fallback);
    }
    return fallback;
  }

  static String categoryName(dynamic category, {String fallback = 'Service'}) {
    if (category is Map) {
      return safeText(category['name'], fallback: fallback);
    }
    return safeText(category, fallback: fallback);
  }

  static String formatStamp(String? raw, {String fallback = ''}) {
    if (raw == null || raw.trim().isEmpty || raw == 'null') return fallback;
    final d = DateTime.tryParse(raw);
    if (d == null) return fallback;
    return AppDateTime.formatDateDisplay(d.toIso8601String()) +
        ' · ' +
        AppDateTime.formatTime12h(
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
        );
  }
}

class JobTimelineStep {
  const JobTimelineStep({
    required this.label,
    required this.detail,
    required this.done,
    this.active = false,
  });

  final String label;
  final String detail;
  final bool done;
  final bool active;
}

/// Build status steps from real job/booking state (no fake dates).
class JobTimeline {
  JobTimeline._();

  static List<JobTimelineStep> fromStatus({
    required String status,
    String? submittedAt,
    String? completedAt,
    bool isAssigned = false,
    bool escrowCredited = false,
    String paymentMethod = '',
  }) {
    final s = status.toLowerCase();
    final submitted = JobTimelineStep(
      label: 'status_submitted'.tr,
      detail: JobDisplay.formatStamp(submittedAt, fallback: '—'),
      done: true,
    );

    if (s == 'cancelled') {
      final matched = JobTimelineStep(
        label: 'status_worker_matched'.tr,
        detail: isAssigned ? 'Assigned' : 'No helper',
        done: isAssigned,
      );
      return [
        submitted,
        matched,
        JobTimelineStep(
          label: 'status_cancelled'.tr,
          detail: 'ui_job_was_cancelled'.tr,
          done: true,
        ),
      ];
    }

    final matchedDone = isAssigned ||
        s == 'in_progress' ||
        s == 'completed';
    final inProgressDone = s == 'in_progress' || s == 'completed';
    final inProgressActive = s == 'in_progress';
    final completedDone = s == 'completed';

    // Escrow is credited on complete for online jobs in this app.
    final paymentDone = completedDone;
    final paymentDetail = s == 'pending_payment'
        ? 'ui_awaiting_payment'.tr
        : (completedDone ? 'Processed' : 'Pending');

    return [
      submitted,
      JobTimelineStep(
        label: 'status_worker_matched'.tr,
        detail: matchedDone
            ? (s == 'in_progress' || s == 'completed' ? 'Accepted' : 'Assigned')
            : (s == 'open' ? 'Looking for helper' : 'Pending'),
        done: matchedDone,
      ),
      JobTimelineStep(
        label: 'status_in_progress'.tr,
        detail: inProgressActive
            ? 'ui_started'.tr
            : (inProgressDone
                ? JobDisplay.formatStamp(completedAt, fallback: 'ui_started'.tr)
                : (s == 'pending_payment'
                    ? 'ui_after_payment'.tr
                    : (s == 'open' ? 'After a helper accepts' : 'Pending'))),
        done: inProgressDone,
        active: inProgressActive,
      ),
      JobTimelineStep(
        label: 'status_completed'.tr,
        detail: completedDone
            ? JobDisplay.formatStamp(completedAt, fallback: 'status_completed'.tr)
            : 'status_pending'.tr,
        done: completedDone,
      ),
      JobTimelineStep(
        label: 'status_payment_processed'.tr,
        detail: paymentDetail,
        done: paymentDone && completedDone,
      ),
    ];
  }

  /// From raw job/assigned-jobs API map.
  static List<JobTimelineStep> fromJobMap(Map job) {
    final status = JobDisplay.safeText(job['status'], fallback: 'open');
    final assignedTo = job['assignedTo'];
    final hasAssignee = assignedTo != null &&
        assignedTo.toString().isNotEmpty &&
        assignedTo != 'null';
    return fromStatus(
      status: status,
      submittedAt: JobDisplay.safeText(job['createdAt']),
      completedAt: JobDisplay.safeText(job['completedAt']),
      isAssigned: hasAssignee,
      escrowCredited: job['escrowCredited'] == true,
      paymentMethod: JobDisplay.safeText(job['paymentMethod']),
    );
  }
}
