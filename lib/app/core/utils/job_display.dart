import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/data/models/home_models.dart' show localizedCategoryName;
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

  static String categoryName(dynamic category, {String fallback = ''}) {
    if (category is Map) {
      return safeText(localizedCategoryName(category), fallback: fallback);
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

/// Build status steps from the real job state and timestamps (no invented dates):
/// submitted → helper matched → on the way → arrived → work finished → completed → paid.
class JobTimeline {
  JobTimeline._();

  static String _stamp(String? raw, String fallback) =>
      JobDisplay.formatStamp(raw, fallback: fallback);

  static List<JobTimelineStep> fromStatus({
    required String status,
    String? submittedAt,
    String? acceptedAt,
    String? onTheWayAt,
    String? arrivedAt,
    String? helperFinishedAt,
    String? completedAt,
    String? cancelledAt,
    bool isAssigned = false,
    bool escrowCredited = false,
    String paymentMethod = '',
  }) {
    final s = status.toLowerCase();
    final submitted = JobTimelineStep(
      label: 'status_submitted'.tr,
      detail: _stamp(submittedAt, '—'),
      done: true,
    );

    if (s == 'cancelled') {
      return [
        submitted,
        JobTimelineStep(
          label: 'status_worker_matched'.tr,
          detail: isAssigned ? _stamp(acceptedAt, 'job_step_assigned'.tr) : 'job_step_no_helper'.tr,
          done: isAssigned,
        ),
        JobTimelineStep(
          label: 'status_cancelled'.tr,
          detail: _stamp(cancelledAt, 'ui_job_was_cancelled'.tr),
          done: true,
        ),
      ];
    }

    final matched = isAssigned ||
        s == 'in_progress' ||
        s == 'on_the_way' ||
        s == 'arrived' ||
        s == 'completed';
    final onTheWay = s == 'on_the_way' || s == 'arrived' || s == 'completed';
    final arrived = s == 'arrived' || s == 'completed';
    final finished = (helperFinishedAt != null && helperFinishedAt.isNotEmpty) || s == 'completed';
    final completed = s == 'completed';
    final isCash = paymentMethod.toLowerCase() == 'cash';
    final paid = completed && (isCash || escrowCredited);

    return [
      submitted,
      JobTimelineStep(
        label: 'status_worker_matched'.tr,
        detail: matched
            ? _stamp(acceptedAt, 'job_step_accepted'.tr)
            : (s == 'open' ? 'job_step_looking'.tr : 'status_pending'.tr),
        done: matched,
        active: s == 'in_progress',
      ),
      JobTimelineStep(
        label: 'job_step_on_the_way'.tr,
        detail: onTheWay ? _stamp(onTheWayAt, 'job_step_done'.tr) : 'job_step_after_accept'.tr,
        done: onTheWay,
        active: s == 'on_the_way',
      ),
      JobTimelineStep(
        label: 'job_step_arrived'.tr,
        detail: arrived ? _stamp(arrivedAt, 'job_step_done'.tr) : 'status_pending'.tr,
        done: arrived,
        active: s == 'arrived' && !finished,
      ),
      JobTimelineStep(
        label: 'job_step_work_finished'.tr,
        detail: finished ? _stamp(helperFinishedAt, 'job_step_done'.tr) : 'status_pending'.tr,
        done: finished,
        active: finished && !completed,
      ),
      JobTimelineStep(
        label: 'status_completed'.tr,
        detail: completed ? _stamp(completedAt, 'status_completed'.tr) : 'status_pending'.tr,
        done: completed,
      ),
      JobTimelineStep(
        label: 'status_payment_processed'.tr,
        detail: s == 'pending_payment'
            ? 'ui_awaiting_payment'.tr
            : (paid ? 'job_step_processed'.tr : 'status_pending'.tr),
        done: paid,
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
      acceptedAt: JobDisplay.safeText(job['acceptedAt']),
      onTheWayAt: JobDisplay.safeText(job['onTheWayAt']),
      arrivedAt: JobDisplay.safeText(job['arrivedAt']),
      helperFinishedAt: JobDisplay.safeText(job['helperFinishedAt']),
      completedAt: JobDisplay.safeText(job['completedAt']),
      cancelledAt: JobDisplay.safeText(job['cancelledAt']),
      isAssigned: hasAssignee,
      escrowCredited: job['escrowCredited'] == true,
      paymentMethod: JobDisplay.safeText(job['paymentMethod']),
    );
  }
}
