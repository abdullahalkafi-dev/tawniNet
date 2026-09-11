import '../../core/constants/api_constants.dart';

class AuthUser {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final String? phone;
  final String? bio;
  final String role;
  final String status;
  final bool isPhoneVerified;
  final String? helperApplicationStatus;
  final bool isHelperFormSubmitted;
  final String? rejectionReason;
  final String? address;
  final String? city;
  final int? age;
  final double? latitude;
  final double? longitude;

  // Didit & Appeal fields
  final String? diditSessionId;
  final String? diditStatus;
  final String? diditDecisionReason;
  final String? maskedDocumentNumber;
  final String? appealStatus;
  final int appealCount;
  final String? appealMessage;

  // Helper-specific fields
  final dynamic serviceType;
  final double? pricePerHour;
  final int? experience;
  final double? serviceRadius;
  final String? language;
  final List<String>? profilePhotos;
  final String? documentType;
  final String? documentUrl;
  final String? selfieUrl;

  AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.phone,
    this.bio,
    required this.role,
    required this.status,
    this.isPhoneVerified = false,
    this.helperApplicationStatus,
    this.isHelperFormSubmitted = false,
    this.rejectionReason,
    this.address,
    this.city,
    this.age,
    this.latitude,
    this.longitude,
    this.diditSessionId,
    this.diditStatus,
    this.diditDecisionReason,
    this.maskedDocumentNumber,
    this.appealStatus,
    this.appealCount = 0,
    this.appealMessage,
    this.serviceType,
    this.pricePerHour,
    this.experience,
    this.serviceRadius,
    this.language,
    this.profilePhotos,
    this.documentType,
    this.documentUrl,
    this.selfieUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lon;
    if (json['location'] != null && json['location']['coordinates'] != null) {
      final coords = (json['location']['coordinates'] as List);
      if (coords.length >= 2) {
        lon = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
    }
    return AuthUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      avatar: ApiConstants.resolveImageUrl(json['avatar']),
      phone: json['phone'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      isPhoneVerified: json['isPhoneVerified'] ?? true,
      helperApplicationStatus: json['helperApplicationStatus'],
      isHelperFormSubmitted: json['isHelperFormSubmitted'] ?? false,
      rejectionReason: json['rejectionReason'],
      address: json['address'],
      city: json['city'],
      age: json['age'] is num ? (json['age'] as num).toInt() : (json['age'] != null ? int.tryParse(json['age'].toString()) : null),
      latitude: lat,
      longitude: lon,
      diditSessionId: json['diditSessionId'],
      diditStatus: json['diditStatus'],
      diditDecisionReason: json['diditDecisionReason'],
      maskedDocumentNumber: json['maskedDocumentNumber'],
      appealStatus: json['appealStatus'],
      appealCount: json['appealCount'] ?? 0,
      appealMessage: json['appealMessage'],
      serviceType: json['serviceType'],
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      experience: json['experience'] is num ? (json['experience'] as num).toInt() : (json['experience'] != null ? int.tryParse(json['experience'].toString()) : null),
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      language: json['language'],
      profilePhotos: (json['profilePhotos'] as List?)
          ?.map((e) => ApiConstants.resolveImageUrl(e.toString()) ?? e.toString())
          .toList(),
      documentType: json['documentType'],
      documentUrl: ApiConstants.resolveImageUrl(json['documentUrl']),
      selfieUrl: ApiConstants.resolveImageUrl(json['selfieUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'bio': bio,
      'role': role,
      'status': status,
      'isPhoneVerified': isPhoneVerified,
      'helperApplicationStatus': helperApplicationStatus,
      'isHelperFormSubmitted': isHelperFormSubmitted,
      'rejectionReason': rejectionReason,
      'address': address,
      'city': city,
      'age': age,
      'location': latitude != null && longitude != null
          ? {'type': 'Point', 'coordinates': [longitude, latitude]}
          : null,
      'diditSessionId': diditSessionId,
      'diditStatus': diditStatus,
      'diditDecisionReason': diditDecisionReason,
      'maskedDocumentNumber': maskedDocumentNumber,
      'appealStatus': appealStatus,
      'appealCount': appealCount,
      'appealMessage': appealMessage,
      'serviceType': serviceType,
      'pricePerHour': pricePerHour,
      'experience': experience,
      'serviceRadius': serviceRadius,
      'language': language,
      'profilePhotos': profilePhotos,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'selfieUrl': selfieUrl,
    };
  }

  bool get hasLocation =>
      (latitude != null && longitude != null && (latitude != 0 || longitude != 0)) ||
      (address != null && address!.trim().isNotEmpty);

  bool get isHelper => role == 'helper';
  bool get isApproved => helperApplicationStatus == 'approved';
  bool get isPending => helperApplicationStatus == 'pending';
  bool get isRejected => helperApplicationStatus == 'rejected';
}
