import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/core/utils/datetime_format.dart';
import 'package:awnneaapp/app/data/models/home_models.dart' show localizedCategoryName;
import 'package:get/get.dart';

/// Where a job stands. `inProgress` = a helper accepted it (the work has not started),
/// then the helper travels (`onTheWay`), `arrived`, and the client confirms → `completed`.
enum BookingStatus {
  pendingPayment,
  open,
  inProgress,
  onTheWay,
  arrived,
  completed,
  cancelled,
  unknown,
}

BookingStatus bookingStatusFromApi(String raw) {
  switch (raw.toLowerCase()) {
    case 'pending_payment':
      return BookingStatus.pendingPayment;
    case 'open':
    case 'assigned':
      return BookingStatus.open;
    case 'in_progress':
    case 'inprogress':
      return BookingStatus.inProgress;
    case 'on_the_way':
      return BookingStatus.onTheWay;
    case 'arrived':
      return BookingStatus.arrived;
    case 'completed':
      return BookingStatus.completed;
    case 'cancelled':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.unknown;
  }
}

class MyReview {
  const MyReview({
    required this.rating,
    this.comment = '',
    this.createdAt = '',
    this.id = '',
  });

  final String id;
  final num rating;
  final String comment;
  final String createdAt;

  factory MyReview.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'];
    final rating = ratingRaw is num
        ? ratingRaw
        : (num.tryParse(ratingRaw?.toString() ?? '') ?? 0);
    return MyReview(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      rating: rating,
      comment: (json['comment'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class Booking {
  final String id;
  final String workerUserId;
  final String workerName;
  final String workerImage;
  final String workerPhone;
  final String category;
  final BookingStatus status;
  final String jobType;
  final String date;
  final String time;
  final String location;

  /// TOTAL in MAD (hourly: rate × hours, computed by the server).
  final double budget;
  final String budgetType; // fixed | hourly
  final double? hourlyRate;
  final double? hours;
  final String description;
  final List<String> photos;
  final String? cancellationReason;
  final String cancelledByRole;
  final String createdAt;
  final String completedAt;
  final String cancelledAt;
  final String paymentMethod;
  final bool escrowCredited;
  final bool hasMyReview;
  final MyReview? myReview;
  final bool hasReviewFromOther;
  final MyReview? reviewFromOther;
  final String refundStatus;
  final String refundReference;
  final double? latitude;
  final double? longitude;

  /// The helper said the work is done; the client confirms (or it completes by itself).
  final DateTime? helperFinishedAt;
  final DateTime? autoCompleteAt;
  final DateTime? startAt;
  final bool disputeOpen;
  final double? feePercentage;
  final double? helperNet;
  final double? commissionDeducted;

  String get title => jobType;

  Booking({
    required this.id,
    required this.workerUserId,
    required this.workerName,
    required this.workerImage,
    this.workerPhone = '',
    required this.category,
    required this.status,
    required this.jobType,
    required this.date,
    required this.time,
    required this.location,
    required this.budget,
    this.budgetType = 'fixed',
    this.hourlyRate,
    this.hours,
    required this.description,
    required this.photos,
    this.cancellationReason,
    this.cancelledByRole = '',
    this.createdAt = '',
    this.completedAt = '',
    this.cancelledAt = '',
    this.paymentMethod = '',
    this.escrowCredited = false,
    this.hasMyReview = false,
    this.myReview,
    this.hasReviewFromOther = false,
    this.reviewFromOther,
    this.refundStatus = 'none',
    this.refundReference = '',
    this.latitude,
    this.longitude,
    this.helperFinishedAt,
    this.autoCompleteAt,
    this.startAt,
    this.disputeOpen = false,
    this.feePercentage,
    this.helperNet,
    this.commissionDeducted,
  });

  /// A helper is assigned and the job is not over.
  bool get isUnderway =>
      status == BookingStatus.inProgress ||
      status == BookingStatus.onTheWay ||
      status == BookingStatus.arrived;

  /// Live tracking only makes sense while the helper is travelling.
  bool get canTrack => status == BookingStatus.onTheWay && latitude != null && longitude != null;

  bool get helperSaysFinished => helperFinishedAt != null && isUnderway;

  bool get isHourly => budgetType == 'hourly';

  /// Neither side can walk away alone any more: support decides.
  bool get needsSupportToCancel => status == BookingStatus.arrived || helperFinishedAt != null;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final assigned = json['assignedTo'] is Map
        ? Map<String, dynamic>.from(json['assignedTo'] as Map)
        : null;
    final cat = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;

    final rawPhotos = json['images'] ?? json['photos'] ?? [];
    final List<String> photoList = [];
    if (rawPhotos is List) {
      for (var p in rawPhotos) {
        if (p != null) {
          photoList.add(ApiConstants.resolveImageUrl(p.toString()) ?? p.toString());
        }
      }
    }

    // Prefer the job/offer work day. Do not fall back to createdAt.
    final rawDate = json['date']?.toString() ?? '';
    final startRaw = json['startTime']?.toString() ?? '';
    final endRaw = json['endTime']?.toString() ?? '';
    final start12 = AppDateTime.formatTime12h(startRaw);
    final end12 = AppDateTime.formatTime12h(endRaw);
    final timeText = start12.isNotEmpty
        ? (end12.isNotEmpty ? '$start12 - $end12' : start12)
        : (json['preferredTime']?.toString() ?? 'ui_flexible'.tr);

    // Text address only — never display raw lat/lng or GeoJSON.
    String address = (json['address'] ?? '').toString();
    if (address == 'null' || address.trim().isEmpty) {
      address = '';
    }

    final budgetRaw = json['budget'];
    double budget = 0;
    if (budgetRaw is num) {
      budget = budgetRaw.toDouble();
    } else if (budgetRaw is String) {
      budget = double.tryParse(budgetRaw) ?? 0;
    }

    double? lat;
    double? lon;
    if (json['location'] is Map) {
      final loc = json['location'] as Map;
      final coords = loc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lon = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    } else if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num?)?.toDouble();
      lon = (json['longitude'] as num?)?.toDouble();
    }

    DateTime? when(dynamic v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

    return Booking(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      workerUserId: assigned != null
          ? (assigned['_id'] ?? assigned['id'] ?? '').toString()
          : '',
      workerName: assigned != null
          ? ((assigned['name'] ?? 'ui_helper'.tr).toString())
          : 'ui_looking_for_helper'.tr,
      workerImage: assigned != null ? (assigned['avatar'] ?? '').toString() : '',
      workerPhone: assigned != null ? (assigned['phone'] ?? '').toString() : '',
      category: cat != null
          ? (localizedCategoryName(cat).isNotEmpty
              ? localizedCategoryName(cat)
              : 'ui_service'.tr)
          : ((json['title'] ?? 'ui_service'.tr).toString()),
      status: bookingStatusFromApi((json['status'] ?? '').toString()),
      jobType: (json['title'] ?? 'ui_service'.tr).toString(),
      date: AppDateTime.formatDateDisplay(rawDate),
      time: timeText,
      location: address,
      budget: budget,
      budgetType: (json['budgetType'] ?? 'fixed').toString(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      hours: (json['hours'] as num?)?.toDouble(),
      description: (json['description'] ?? '').toString(),
      photos: photoList,
      cancellationReason: json['cancellationReason']?.toString(),
      cancelledByRole: (json['cancelledByRole'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      completedAt: (json['completedAt'] ?? '').toString(),
      cancelledAt: (json['cancelledAt'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      escrowCredited: json['escrowCredited'] == true,
      hasMyReview: json['hasMyReview'] == true,
      myReview: json['myReview'] is Map
          ? MyReview.fromJson(Map<String, dynamic>.from(json['myReview'] as Map))
          : null,
      hasReviewFromOther: json['hasReviewFromOther'] == true,
      reviewFromOther: json['reviewFromOther'] is Map
          ? MyReview.fromJson(
              Map<String, dynamic>.from(json['reviewFromOther'] as Map))
          : null,
      refundStatus: (json['refundStatus'] ?? 'none').toString(),
      refundReference: (json['refundReference'] ?? '').toString(),
      latitude: lat,
      longitude: lon,
      helperFinishedAt: when(json['helperFinishedAt']),
      autoCompleteAt: when(json['autoCompleteAt']),
      startAt: when(json['startAt']),
      disputeOpen: json['disputeOpen'] == true,
      feePercentage: (json['feePercentage'] as num?)?.toDouble(),
      helperNet: (json['helperNet'] as num?)?.toDouble(),
      commissionDeducted: (json['commissionDeducted'] as num?)?.toDouble(),
    );
  }

  String get statusApiValue {
    switch (status) {
      case BookingStatus.pendingPayment:
        return 'pending_payment';
      case BookingStatus.open:
        return 'open';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.onTheWay:
        return 'on_the_way';
      case BookingStatus.arrived:
        return 'arrived';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
      case BookingStatus.unknown:
        return 'unknown';
    }
  }
}
