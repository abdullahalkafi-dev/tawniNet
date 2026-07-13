class AuthUser {
  final String id;
  final String name;
  final String? email;
  final String? avatar;
  final String? phone;
  final String? bio;
  final String role;
  final String status;
  final String? helperApplicationStatus;
  final bool isHelperFormSubmitted;
  final String? rejectionReason;
  final String? address;
  final double? latitude;
  final double? longitude;

  // Helper-specific fields
  final dynamic serviceType;
  final double? pricePerHour;
  final int? experience;
  final double? serviceRadius;
  final String? language;
  final List<String>? profilePhotos;

  AuthUser({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.phone,
    this.bio,
    required this.role,
    required this.status,
    this.helperApplicationStatus,
    this.isHelperFormSubmitted = false,
    this.rejectionReason,
    this.address,
    this.latitude,
    this.longitude,
    this.serviceType,
    this.pricePerHour,
    this.experience,
    this.serviceRadius,
    this.language,
    this.profilePhotos,
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
      avatar: json['avatar'],
      phone: json['phone'],
      bio: json['bio'],
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'active',
      helperApplicationStatus: json['helperApplicationStatus'],
      isHelperFormSubmitted: json['isHelperFormSubmitted'] ?? false,
      rejectionReason: json['rejectionReason'],
      address: json['address'],
      latitude: lat,
      longitude: lon,
      serviceType: json['serviceType'],
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      experience: json['experience'],
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      language: json['language'],
      profilePhotos: (json['profilePhotos'] as List?)
          ?.map((e) => e.toString())
          .toList(),
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
      'helperApplicationStatus': helperApplicationStatus,
      'isHelperFormSubmitted': isHelperFormSubmitted,
      'rejectionReason': rejectionReason,
      'address': address,
      'location': latitude != null && longitude != null
          ? {'type': 'Point', 'coordinates': [longitude, latitude]}
          : null,
      'serviceType': serviceType,
      'pricePerHour': pricePerHour,
      'experience': experience,
      'serviceRadius': serviceRadius,
      'language': language,
      'profilePhotos': profilePhotos,
    };
  }
}
