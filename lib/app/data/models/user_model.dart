import '../../core/constants/api_constants.dart';

class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? coverPhoto;
  final String? bio;
  final String role;
  final String status;

  // Location
  final UserLocation? location;
  final String? address;

  // Helper fields
  final bool isHelperFormSubmitted;
  final String? helperApplicationStatus;
  final String? rejectionReason;
  final List<ApplicationHistoryEntry> applicationHistory;
  final int? age;
  final String? city;
  final String? language;
  final String? serviceType;
  final double? pricePerHour;
  final int? experience;
  final double? serviceRadius;
  final List<String>? profilePhotos;
  final String? documentType;
  final String? documentUrl;
  final String? selfieUrl;

  UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatar,
    this.coverPhoto,
    this.bio,
    required this.role,
    required this.status,
    this.location,
    this.address,
    this.isHelperFormSubmitted = false,
    this.helperApplicationStatus,
    this.rejectionReason,
    this.applicationHistory = const [],
    this.age,
    this.city,
    this.language,
    this.serviceType,
    this.pricePerHour,
    this.experience,
    this.serviceRadius,
    this.profilePhotos,
    this.documentType,
    this.documentUrl,
    this.selfieUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatar: ApiConstants.resolveImageUrl(json['avatar']),
      coverPhoto: ApiConstants.resolveImageUrl(json['coverPhoto']),
      bio: json['bio'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'])
          : null,
      address: json['address'],
      isHelperFormSubmitted: json['isHelperFormSubmitted'] ?? false,
      helperApplicationStatus: json['helperApplicationStatus'],
      rejectionReason: json['rejectionReason'],
      applicationHistory: (json['applicationHistory'] as List?)
              ?.map((e) => ApplicationHistoryEntry.fromJson(e))
              .toList() ??
          [],
      age: json['age'],
      city: json['city'],
      language: json['language'],
      serviceType: json['serviceType'],
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      experience: json['experience'],
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      profilePhotos: (json['profilePhotos'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      documentType: json['documentType'],
      documentUrl: json['documentUrl'],
      selfieUrl: json['selfieUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'coverPhoto': coverPhoto,
      'bio': bio,
      'role': role,
      'status': status,
      'address': address,
      'isHelperFormSubmitted': isHelperFormSubmitted,
      'helperApplicationStatus': helperApplicationStatus,
      'rejectionReason': rejectionReason,
      'age': age,
      'city': city,
      'language': language,
      'serviceType': serviceType,
      'pricePerHour': pricePerHour,
      'experience': experience,
      'serviceRadius': serviceRadius,
      'profilePhotos': profilePhotos,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'selfieUrl': selfieUrl,
    };
  }

  bool get isHelper => role == 'helper';
  bool get isApproved => helperApplicationStatus == 'approved';
  bool get isPending => helperApplicationStatus == 'pending';
  bool get isRejected => helperApplicationStatus == 'rejected';
}

class UserLocation {
  final String type;
  final List<double> coordinates; // [longitude, latitude]

  UserLocation({required this.type, required this.coordinates});

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      type: json['type'] ?? 'Point',
      coordinates: (json['coordinates'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
    );
  }

  double get latitude => coordinates.length > 1 ? coordinates[1] : 0;
  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0;
}

class ApplicationHistoryEntry {
  final DateTime appliedAt;
  final String status;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  ApplicationHistoryEntry({
    required this.appliedAt,
    required this.status,
    this.rejectionReason,
    this.reviewedAt,
  });

  factory ApplicationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ApplicationHistoryEntry(
      appliedAt: DateTime.parse(json['appliedAt']),
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
    );
  }

  int get attemptNumber => 0; // Set externally if needed
}
