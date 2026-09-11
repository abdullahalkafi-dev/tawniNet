import 'package:awnneaapp/app/core/utils/datetime_format.dart';

enum BookingStatus {
  pendingPayment,
  open,
  inProgress,
  completed,
  cancelled,
}

class MyReview {
  const MyReview({
    required this.rating,
    this.comment = '',
    this.createdAt = '',
  });

  final num rating;
  final String comment;
  final String createdAt;

  factory MyReview.fromJson(Map<String, dynamic> json) {
    final ratingRaw = json['rating'];
    final rating = ratingRaw is num
        ? ratingRaw
        : (num.tryParse(ratingRaw?.toString() ?? '') ?? 0);
    return MyReview(
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
  final String category;
  final BookingStatus status;
  final String jobType;
  final String date;
  final String time;
  final String location;
  final double budget;
  final String description;
  final List<String> photos;
  final String? cancellationReason;
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

  Booking({
    required this.id,
    required this.workerUserId,
    required this.workerName,
    required this.workerImage,
    required this.category,
    required this.status,
    required this.jobType,
    required this.date,
    required this.time,
    required this.location,
    required this.budget,
    required this.description,
    required this.photos,
    this.cancellationReason,
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
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final assigned = json['assignedTo'] is Map
        ? Map<String, dynamic>.from(json['assignedTo'] as Map)
        : null;
    final cat = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;

    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    BookingStatus bStatus = BookingStatus.open;
    if (statusStr == 'completed') {
      bStatus = BookingStatus.completed;
    } else if (statusStr == 'cancelled') {
      bStatus = BookingStatus.cancelled;
    } else if (statusStr == 'pending_payment') {
      bStatus = BookingStatus.pendingPayment;
    } else if (statusStr == 'in_progress' || statusStr == 'inprogress') {
      bStatus = BookingStatus.inProgress;
    } else if (statusStr == 'open' || statusStr == 'assigned') {
      bStatus = BookingStatus.open;
    }

    final rawPhotos = json['images'] ?? json['photos'] ?? [];
    final List<String> photoList = [];
    if (rawPhotos is List) {
      for (var p in rawPhotos) {
        if (p != null) photoList.add(p.toString());
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
        : (json['preferredTime']?.toString() ?? 'Flexible');

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

    return Booking(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      workerUserId: assigned != null
          ? (assigned['_id'] ?? assigned['id'] ?? '').toString()
          : '',
      workerName: assigned != null
          ? ((assigned['name'] ?? 'Assigned Helper').toString())
          : 'Looking for Helper...',
      workerImage: assigned != null ? (assigned['avatar'] ?? '').toString() : '',
      category: cat != null
          ? ((cat['name'] ?? 'Service').toString())
          : ((json['title'] ?? 'Service').toString()),
      status: bStatus,
      jobType: (json['title'] ?? 'Service').toString(),
      date: AppDateTime.formatDateDisplay(rawDate),
      time: timeText,
      location: address,
      budget: budget,
      description: (json['description'] ?? '').toString(),
      photos: photoList,
      cancellationReason: json['cancellationReason']?.toString(),
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
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }
}
