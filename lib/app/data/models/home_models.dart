import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import 'package:get/get.dart';

/// Name of a category/service in the app language (falls back to English, then
/// to the raw name). Works for the `{name, names}` object the API sends.
String localizedCategoryName(dynamic category) {
  if (category is! Map) return category?.toString() ?? '';
  final raw = category['displayName']?.toString();
  final names = category['names'];
  final lang = Get.locale?.languageCode ?? 'en';
  if (names is Map) {
    final local = names[lang]?.toString();
    if (local != null && local.trim().isNotEmpty) return local;
    final en = names['en']?.toString();
    if (en != null && en.trim().isNotEmpty) return en;
  }
  if (raw != null && raw.trim().isNotEmpty) return raw;
  return category['name']?.toString() ?? '';
}

class Category {
  final String id;

  /// Name in the app language.
  final String name;

  /// Stable identifier (e.g. `home_cleaning`) — icons/colors are chosen by it.
  final String? slug;
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
    this.slug,
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

  /// Icon bundled with the app. Used when the category still has its standard
  /// icon (same file name); an icon an admin replaced is loaded from the server.
  String? get bundledIconAsset {
    final asset = _bundledIcons[slug];
    if (asset == null) return null;
    final url = iconUrl;
    if (url == null || url.isEmpty) return asset;
    final fileName = asset.split('/').last;
    return url.endsWith('/$fileName') ? asset : null;
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString();
    final style = _style[slug] ?? _legacyStyleByName(json['name']?.toString());
    return Category(
      id: json['_id']?.toString() ?? '',
      name: localizedCategoryName(json),
      slug: slug,
      iconUrl: ApiConstants.resolveImageUrl(json['icon'] as String?),
      icon: style?.icon ?? Icons.handyman_outlined,
      color: style?.color ?? Colors.grey,
      minHourlyRate: (json['minHourlyRate'] as num?)?.toDouble(),
      suggestedPriceMin: (json['suggestedPriceMin'] as num?)?.toDouble(),
      suggestedPriceMax: (json['suggestedPriceMax'] as num?)?.toDouble(),
    );
  }

  static const _bundledIcons = <String, String>{
    'home_cleaning': 'assets/category_icons/cleaning_icon.svg',
    'furniture_assembly': 'assets/category_icons/furniture_assembly_icon.svg',
    'gardening': 'assets/category_icons/garden_icon.svg',
    'tech_support': 'assets/category_icons/tech_support_icon.svg',
    'tutoring': 'assets/category_icons/tutoring_icon.svg',
    'pet_care': 'assets/category_icons/pet_care_icon.svg',
    'tailoring': 'assets/category_icons/tailoring_icon.svg',
    'events': 'assets/category_icons/event_helper_icon.svg',
    'car_wash': 'assets/category_icons/car_wash_icon.svg',
  };

  static const _style = <String, _CategoryStyle>{
    'home_cleaning': _CategoryStyle(Icons.cleaning_services_outlined, Colors.teal),
    'furniture_assembly': _CategoryStyle(Icons.chair_alt_outlined, Colors.deepOrange),
    'gardening': _CategoryStyle(Icons.yard_outlined, Colors.green),
    'tech_support': _CategoryStyle(Icons.devices_other_outlined, Colors.indigo),
    'tutoring': _CategoryStyle(Icons.school_outlined, Colors.purple),
    'pet_care': _CategoryStyle(Icons.pets_outlined, Colors.brown),
    'tailoring': _CategoryStyle(Icons.content_cut, Colors.pink),
    'events': _CategoryStyle(Icons.celebration_outlined, Colors.amber),
    'car_wash': _CategoryStyle(Icons.local_car_wash_outlined, Colors.blue),
  };

  /// Categories created before slugs existed were recognised by their English name.
  static _CategoryStyle? _legacyStyleByName(String? name) {
    final n = (name ?? '').toLowerCase();
    if (n.contains('clean')) return _style['home_cleaning'];
    if (n.contains('garden')) return _style['gardening'];
    if (n.contains('tech') || n.contains('electric')) return _style['tech_support'];
    if (n.contains('tutor')) return _style['tutoring'];
    if (n.contains('pet')) return _style['pet_care'];
    if (n.contains('tailor')) return _style['tailoring'];
    if (n.contains('event')) return _style['events'];
    if (n.contains('furniture') || n.contains('assembly')) return _style['furniture_assembly'];
    if (n.contains('car')) return _style['car_wash'];
    return null;
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;
  const _CategoryStyle(this.icon, this.color);
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

  /// Hourly jobs: rate × hours = [budget] (computed by the server).
  final double? hourlyRate;
  final double? hours;
  bool get hasHours => hours != null && hours! > 0;

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
    this.hourlyRate,
    this.hours,
  }) : name = name ?? helperName;

  /// Parses a helper from `/user/helpers/search`. Single source of truth for
  /// helper cards (home, find helper, category, search).
  factory HelperJob.fromHelperJson(Map<String, dynamic> map) {
    final serviceType = map['serviceType'];
    String category = 'ui_general'.tr;
    if (serviceType is Map) {
      final n = localizedCategoryName(serviceType);
      if (n.isNotEmpty) category = n;
    } else if (serviceType is String && serviceType.isNotEmpty) {
      category = serviceType;
    }
    final rawAvatar = map['avatar'];
    final avatar = rawAvatar is String && rawAvatar.isNotEmpty
        ? (ApiConstants.resolveImageUrl(rawAvatar) ?? rawAvatar)
        : '';
    final id = map['_id']?.toString() ?? '';
    final name = map['name']?.toString() ?? 'ui_helper'.tr;
    final bio = map['bio']?.toString();
    final area = (map['area'] ?? map['city'] ?? map['address'])?.toString();
    final distKm = map['distanceKm'];
    return HelperJob(
      id: id,
      helperName: name,
      helperImage: avatar,
      postedByUserId: id,
      timeAgo: _formatDate(map['createdAt']?.toString()),
      category: category,
      title: bio ?? 'ui_available_for_hire'.tr,
      description: bio ?? 'ui_professional_helper_in_your_area'.tr,
      distance: distKm is num
          ? '${distKm.toStringAsFixed(1)} km'
          : ((area != null && area.isNotEmpty) ? area : 'ui_nearby'.tr),
      distanceKm: distKm is num ? distKm.toDouble() : null,
      name: name,
      avatar: avatar,
      bio: bio,
      address: area,
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
      final n = localizedCategoryName(json['category']);
      if (n.isNotEmpty) category = n;
    } else if (json['serviceType'] is Map) {
      final n = localizedCategoryName(json['serviceType']);
      if (n.isNotEmpty) category = n;
    } else if (json['serviceType'] is String) {
      category = json['serviceType'];
    }

    // Helper info from postedBy or top-level
    String avatarUrl = '';
    String helperName = 'ui_client'.tr;
    String postedByUserId = '';
    if (json['postedBy'] is Map) {
      postedByUserId = json['postedBy']['_id']?.toString() ?? '';
      helperName = json['postedBy']['name']?.toString() ?? 'ui_client'.tr;
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
      title: json['title'] ?? 'ui_available_for_hire'.tr,
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
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      hours: (json['hours'] as num?)?.toDouble(),
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
    if (dateStr == null) return 'ui_recently'.tr;
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) {
        return 'time_months_ago'.trParams({'n': '${(diff.inDays / 30).floor()}'});
      }
      if (diff.inDays > 0) return 'time_days_ago'.trParams({'n': '${diff.inDays}'});
      if (diff.inHours > 0) return 'time_hours_ago'.trParams({'n': '${diff.inHours}'});
      if (diff.inMinutes > 0) return 'time_minutes_ago'.trParams({'n': '${diff.inMinutes}'});
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
  final double? serviceRadius;
  final String? address;
  final String? city;
  final String? language;
  final List<String> profilePhotos;
  final DateTime? createdAt;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isAvailable;
  final double? distanceKm;

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
    this.isAvailable = true,
    this.distanceKm,
  });

  factory HelperProfileData.fromJson(Map<String, dynamic> json) {
    String categoryName = 'ui_general'.tr;
    String? categoryId;
    if (json['serviceType'] is Map) {
      final n = localizedCategoryName(json['serviceType']);
      if (n.isNotEmpty) categoryName = n;
      categoryId = json['serviceType']['_id']?.toString();
    } else if (json['serviceType'] is String) {
      categoryName = json['serviceType'];
    }

    return HelperProfileData(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'ui_helper'.tr,
      avatar: ApiConstants.resolveImageUrl(json['avatar'] as String?),
      bio: json['bio'] as String?,
      categoryName: categoryName,
      categoryId: categoryId,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      experience: (json['experience'] as num?)?.toInt(),
      serviceRadius: (json['serviceRadius'] as num?)?.toDouble(),
      address: (json['area'] ?? json['address']) as String?,
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
      isAvailable: json['isAvailable'] != false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}
