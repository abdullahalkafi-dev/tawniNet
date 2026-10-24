import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import 'package:get/get.dart';

class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final IconData icon;
  final Color color;

  // Price guidance in MAD (set by admins per category); null = no guidance.
  final double? minHourlyRate;
  final double? suggestedPriceMin;
  final double? suggestedPriceMax;

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.icon,
    required this.color,
    this.minHourlyRate,
    this.suggestedPriceMin,
    this.suggestedPriceMax,
  });

  bool get hasPriceGuidance =>
      minHourlyRate != null || suggestedPriceMin != null || suggestedPriceMax != null;

  /// Returns category icon URL (backend resolves key to full proxy URL)
  String? get resolvedIconUrl {
    if (iconUrl == null || iconUrl!.isEmpty) return null;
    return iconUrl;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    final mapping = _categoryMapping[name];
    return Category(
      id: json['_id'] ?? '',
      name: name,
      iconUrl: ApiConstants.resolveImageUrl(json['icon'] as String?),
      icon: mapping?['icon'] ?? Icons.help_outline,
      color: mapping?['color'] ?? Colors.grey,
      minHourlyRate: (json['minHourlyRate'] as num?)?.toDouble(),
      suggestedPriceMin: (json['suggestedPriceMin'] as num?)?.toDouble(),
      suggestedPriceMax: (json['suggestedPriceMax'] as num?)?.toDouble(),
    );
  }

  static final Map<String, Map<String, dynamic>> _categoryMapping = {
    'Carrying': {'icon': Icons.inventory_2_outlined, 'color': Colors.orange},
    'Cleaning': {'icon': Icons.home_repair_service_outlined, 'color': Colors.yellow},
    'Electrician': {'icon': Icons.bolt, 'color': Colors.purple},
    'Barber': {'icon': Icons.content_cut, 'color': Colors.red},
    'Floor': {'icon': Icons.format_paint_outlined, 'color': Colors.teal},
    'Shifting': {'icon': Icons.local_shipping_outlined, 'color': Colors.amber},
    'Garden': {'icon': Icons.opacity_outlined, 'color': Colors.orangeAccent},
    'Plumbing': {'icon': Icons.plumbing, 'color': Colors.blue},
    'Moving': {'icon': Icons.directions_bus_outlined, 'color': Colors.blue},
    'Painting': {'icon': Icons.format_paint, 'color': Colors.deepOrange},
    'Mechanic': {'icon': Icons.build, 'color': Colors.brown},
    'Laundry': {'icon': Icons.local_laundry_service, 'color': Colors.cyan},
  };
}

class HelperJob {
  final String id;
  final String helperName;
  final String helperImage;
  final String postedByUserId;
  final String timeAgo;
  final String category;
  final String title;
  final String description;
  final String distance;
  final double? distanceKm;

  // Additional fields from backend
  final String name;
  final String? avatar;
  final String? bio;
  final String? address;

  // Job-specific fields from backend
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final double? budget;
  final String? budgetType; // 'hourly' or 'fixed'
  final String? paymentMethod; // 'online' or 'cash'
  final String? status; // 'open', 'completed', 'cancelled'
  final List<String> images;
  final double rating;
  final int reviewCount;

  // Helper-card fields (from /user/helpers/search)
  final bool isVerified;
  final List<String> workPhotos;
  final double? pricePerHour;

  String get price => budget != null ? 'MAD ${budget!.toStringAsFixed(0)}' : '';

  HelperJob({
    required this.id,
    required this.helperName,
    required this.helperImage,
    required this.postedByUserId,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.description,
    required this.distance,
    this.distanceKm,
    String? name,
    this.avatar,
    this.bio,
    this.address,
    this.date,
    this.startTime,
    this.endTime,
    this.budget,
    this.budgetType,
    this.paymentMethod,
    this.status,
    this.images = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.isVerified = false,
    this.workPhotos = const [],
    this.pricePerHour,
  }) : name = name ?? helperName;

  /// Parses a helper from `/user/helpers/search`. Single source of truth for
  /// helper cards (home, find helper, category, search).
  factory HelperJob.fromHelperJson(Map<String, dynamic> map) {
    final serviceType = map['serviceType'];
    String category = 'ui_general'.tr;
    if (serviceType is Map) {
      category = serviceType['name']?.toString() ?? 'General';
    } else if (serviceType is String) {
      category = serviceType;
    }
    final rawAvatar = map['avatar'];
    final avatar = rawAvatar is String && rawAvatar.isNotEmpty
        ? (ApiConstants.resolveImageUrl(rawAvatar) ?? rawAvatar)
        : '';
    final id = map['_id']?.toString() ?? '';
    final name = map['name']?.toString() ?? 'Helper';
    final bio = map['bio']?.toString();
    return HelperJob(
      id: id,
      helperName: name,
      helperImage: avatar,
      postedByUserId: id,
      timeAgo: _formatDate(map['createdAt']?.toString()),
      category: category,
      title: bio ?? 'ui_available_for_hire'.tr,
      description: bio ?? 'ui_professional_helper_in_your_area'.tr,
      distance: map['address']?.toString() ?? 'Nearby',
      name: name,
      avatar: avatar,
      bio: bio,
      address: map['address']?.toString(),
      rating: _toDouble(map['rating']),
      reviewCount: _toDouble(map['reviewCount']).toInt(),
      isVerified: map['isVerified'] == true,
      workPhotos: _toUrlList(map['workPhotos'] ?? map['profilePhotos']),
      pricePerHour: (map['pricePerHour'] as num?)?.toDouble(),
    );
  }

  factory HelperJob.fromJson(Map<String, dynamic> json) {
    // Category from nested object or serviceType
    String category = 'ui_general'.tr;
    if (json['category'] is Map) {
      category = json['category']['name'] as String? ?? 'General';
    } else if (json['serviceType'] is Map) {
      category = json['serviceType']['name'] as String? ?? 'General';
    } else if (json['serviceType'] is String) {
      category = json['serviceType'];
    }

    // Helper info from postedBy or top-level
    String avatarUrl = '';
    String helperName = 'ui_client'.tr;
    String postedByUserId = '';
    if (json['postedBy'] is Map) {
      postedByUserId = json['postedBy']['_id']?.toString() ?? '';
      helperName = json['postedBy']['name']?.toString() ?? 'Client';
      if (json['postedBy']['avatar'] != null && (json['postedBy']['avatar'] as String).isNotEmpty) {
        avatarUrl = ApiConstants.resolveImageUrl(json['postedBy']['avatar']) ?? json['postedBy']['avatar'];
      }
    } else {
      if (json['postedBy'] is String) {
        postedByUserId = json['postedBy'] as String;
      }
      if (json['avatar'] != null && (json['avatar'] as String).isNotEmpty) {
        avatarUrl = ApiConstants.resolveImageUrl(json['avatar']) ?? json['avatar'];
      }
      if (json['name'] != null && (json['name'] as String).isNotEmpty) {
        helperName = json['name'] as String;
      }
    }

    final bio = json['description'] as String?;
    // Short public address only — extra detail lives in chat.
    final rawAddress = json['address'] as String? ?? '';
    String? address;
    if (rawAddress.isNotEmpty) {
      final parts =
          rawAddress.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        address = '${parts[0]}, ${parts[1]}';
      } else {
        address = parts.isNotEmpty ? parts.first : null;
      }
    }

    String distanceText = '';
    double? distanceKm;
    final distKm = json['distanceKm'];
    if (distKm is num) {
      distanceKm = distKm.toDouble();
      distanceText = '${distanceKm.toStringAsFixed(1)} km';
    }

    // Parse job-specific fields
    DateTime? date;
    if (json['date'] != null && json['date'] is String) {
      date = DateTime.tryParse(json['date']);
    }

    List<String> images = [];
    if (json['images'] != null && json['images'] is List) {
      images = (json['images'] as List)
          .whereType<String>()
          .map((img) => ApiConstants.resolveImageUrl(img) ?? img)
          .toList();
    }

    return HelperJob(
      id: json['_id'] ?? '',
      helperName: helperName,
      helperImage: avatarUrl,
      postedByUserId: postedByUserId,
      timeAgo: _formatDate(json['createdAt']),
      category: category,
      title: json['title'] ?? 'Available for hire',
      description: bio ?? 'ui_professional_helper_in_your_area'.tr,
      distance: distanceText,
      distanceKm: distanceKm,
      name: helperName,
      avatar: avatarUrl,
      bio: bio,
      address: address,
      date: date,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      budget: (json['budget'] as num?)?.toDouble(),
      budgetType: json['budgetType'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      status: json['status'] as String?,
      images: images,
      rating: _toDouble(json['rating']),
      reviewCount: _toDouble(json['reviewCount']).toInt(),
    );
  }

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0);

  static List<String> _toUrlList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty && e != 'null')
        .map((e) => ApiConstants.resolveImageUrl(e) ?? e)
        .toList();
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'ui_just_now'.tr;
    } catch (_) {
      return 'ui_recently'.tr;
    }
  }
}

class PopularService {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviews;
  final double pricePerHour;
  final String distance;
  final String image;
  final bool isVerified;

  PopularService({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.pricePerHour,
    required this.distance,
    required this.image,
    this.isVerified = false,
  });
}

class HelperProfileData {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;
  final String categoryName;
  final String? categoryId;
  final double? pricePerHour;
  final int? experience;
  final int? serviceRadius;
  final String? address;
  final String? city;
  final String? language;
  final List<String> profilePhotos;
  final DateTime? createdAt;
  final double rating;
  final int reviewCount;
  final bool isVerified;

  HelperProfileData({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
    this.categoryName = 'General',
    this.categoryId,
    this.pricePerHour,
    this.experience,
    this.serviceRadius,
    this.address,
    this.city,
    this.language,
    this.profilePhotos = const [],
    this.createdAt,
    this.rating = 0,
    this.reviewCount = 0,
    this.isVerified = false,
  });

  factory HelperProfileData.fromJson(Map<String, dynamic> json) {
    String categoryName = 'ui_general'.tr;
    String? categoryId;
    if (json['serviceType'] is Map) {
      categoryName = json['serviceType']['name'] as String? ?? 'General';
      categoryId = json['serviceType']['_id'] as String?;
    } else if (json['serviceType'] is String) {
      categoryName = json['serviceType'];
    }

    return HelperProfileData(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Helper',
      avatar: ApiConstants.resolveImageUrl(json['avatar'] as String?),
      bio: json['bio'] as String?,
      categoryName: categoryName,
      categoryId: categoryId,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      experience: json['experience'] as int?,
      serviceRadius: json['serviceRadius'] as int?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      language: json['language'] as String?,
      profilePhotos: (json['profilePhotos'] as List<dynamic>?)
              ?.map((e) => ApiConstants.resolveImageUrl(e.toString()) ?? e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] == true,
    );
  }
}
