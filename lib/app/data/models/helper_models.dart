enum ApplicationStatus { pending, approved, rejected }

enum JobStatus { submitted, accepted, inProgress, completed, paymentProcessed }

class HelperJobListing {
  final String id;
  final String title;
  final String price;
  final String distance;
  final String category;

  HelperJobListing({
    required this.id,
    required this.title,
    required this.price,
    required this.distance,
    required this.category,
  });
}

class HelperJobApplication {
  final String id;
  final String orderBy;
  final String jobType;
  final String bookingDate;
  final String preferredTime;
  final String location;
  final double budget;
  final String distance;
  final String description;
  final List<String> photos;
  final List<JobStatusUpdate> statusUpdates;

  HelperJobApplication({
    required this.id,
    required this.orderBy,
    required this.jobType,
    required this.bookingDate,
    required this.preferredTime,
    required this.location,
    required this.budget,
    required this.distance,
    required this.description,
    required this.photos,
    required this.statusUpdates,
  });
}

class JobStatusUpdate {
  final String label;
  final String date;
  final bool isCompleted;
  final bool isActive;

  JobStatusUpdate({
    required this.label,
    required this.date,
    required this.isCompleted,
    this.isActive = false,
  });
}

class HelperProfile {
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String location;
  final String avatarUrl;
  final List<String> services;
  final double rating;
  final int reviewCount;
  final bool isAvailable;
  final List<String> photos;

  HelperProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.location,
    required this.avatarUrl,
    required this.services,
    required this.rating,
    required this.reviewCount,
    required this.isAvailable,
    required this.photos,
  });
}

class Review {
  final String id;
  final String reviewerName;
  final String reviewerImage;
  final int rating;
  final String comment;
  final String timeAgo;

  Review({
    required this.id,
    required this.reviewerName,
    required this.reviewerImage,
    required this.rating,
    required this.comment,
    required this.timeAgo,
  });
}

class EarningRecord {
  final String date;
  final String activity;
  final String method;
  final String from;
  final double amount;
  final bool isWithdrawal;

  EarningRecord({
    required this.date,
    required this.activity,
    required this.method,
    required this.from,
    required this.amount,
    this.isWithdrawal = false,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeGroup;
  final String iconType;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeGroup,
    required this.iconType,
  });
}

class ConnectsPackage {
  final int connects;
  final double price;
  final String currency;

  ConnectsPackage({
    required this.connects,
    required this.price,
    required this.currency,
  });
}

class FaqItem {
  final String question;
  final String answer;
  bool isExpanded;

  FaqItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

class CancelledJobDetail {
  final String id;
  final String clientName;
  final String clientImage;
  final String location;
  final String cancelledDate;
  final String cancelledBy;
  final String reason;
  final String jobDate;
  final String jobTime;
  final double serviceFee;
  final String description;

  CancelledJobDetail({
    required this.id,
    required this.clientName,
    required this.clientImage,
    required this.location,
    required this.cancelledDate,
    required this.cancelledBy,
    required this.reason,
    required this.jobDate,
    required this.jobTime,
    required this.serviceFee,
    required this.description,
  });
}
