import 'package:awnneaapp/app/core/utils/datetime_format.dart';

/// Helpers for flattening job API maps into display-safe strings.
class JobDisplay {
  JobDisplay._();

  /// `address` is a string; `location` may be GeoJSON Point.
  static String safeLocation(Map job) {
    final address = job['address']?.toString() ?? '';
    if (address.isNotEmpty && address != 'null') return address;
    final loc = job['location'];
    if (loc is String && loc.isNotEmpty && loc != 'null') return loc;
    if (loc is Map) {
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        return '${coords[1]}, ${coords[0]}';
      }
    }
    return '';
  }

  /// Never surface raw GeoJSON to users.
  static String publicAddress(Map job) {
    final address = job['address']?.toString() ?? '';
    if (address.isNotEmpty && address != 'null') {
      final parts =
          address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      // Drop trailing house/building segments — keep city + street-ish prefix.
      if (parts.length >= 3) {
        return parts.take(parts.length - 1).join(', ');
      }
      return address;
    }
    final city = job['city']?.toString() ?? '';
    if (city.isNotEmpty && city != 'null') return city;
    return '';
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
      label: 'Job Submitted',
      detail: JobDisplay.formatStamp(submittedAt, fallback: '—'),
      done: true,
    );

    if (s == 'cancelled') {
      final matched = JobTimelineStep(
        label: 'Worker Matched',
        detail: isAssigned ? 'Assigned' : 'No helper',
        done: isAssigned,
      );
      return [
        submitted,
        matched,
        const JobTimelineStep(
          label: 'Cancelled',
          detail: 'Job was cancelled',
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
        ? 'Awaiting payment'
        : (completedDone ? 'Processed' : 'Pending');

    return [
      submitted,
      JobTimelineStep(
        label: 'Worker Matched',
        detail: matchedDone
            ? (s == 'in_progress' || s == 'completed' ? 'Accepted' : 'Assigned')
            : (s == 'open' ? 'Looking for helper' : 'Pending'),
        done: matchedDone,
      ),
      JobTimelineStep(
        label: 'In Progress',
        detail: inProgressActive
            ? 'Started'
            : (inProgressDone
                ? JobDisplay.formatStamp(completedAt, fallback: 'Started')
                : (s == 'pending_payment'
                    ? 'After payment'
                    : (s == 'open' ? 'After a helper accepts' : 'Pending'))),
        done: inProgressDone,
        active: inProgressActive,
      ),
      JobTimelineStep(
        label: 'Completed',
        detail: completedDone
            ? JobDisplay.formatStamp(completedAt, fallback: 'Completed')
            : 'Pending',
        done: completedDone,
      ),
      JobTimelineStep(
        label: 'Payment Processed',
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
