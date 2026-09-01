import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';

class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final IconData icon;
  final Color color;

  Category({required this.id, required this.name, this.iconUrl, required this.icon, required this.color});

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
  }) : name = name ?? helperName;

  factory HelperJob.fromJson(Map<String, dynamic> json) {
    // Category from nested object or serviceType
    String category = 'General';
    if (json['category'] is Map) {
      category = json['category']['name'] as String? ?? 'General';
    } else if (json['serviceType'] is Map) {
      category = json['serviceType']['name'] as String? ?? 'General';
    } else if (json['serviceType'] is String) {
      category = json['serviceType'];
    }

    // Helper info from postedBy or top-level
    String avatarUrl = 'https://i.pravatar.cc/150';
    String helperName = 'Helper';
    String postedByUserId = '';
    if (json['postedBy'] is Map) {
      postedByUserId = json['postedBy']['_id'] ?? '';
      helperName = json['postedBy']['name'] ?? 'Helper';
      if (json['postedBy']['avatar'] != null && (json['postedBy']['avatar'] as String).isNotEmpty) {
        avatarUrl = ApiConstants.resolveImageUrl(json['postedBy']['avatar']) ?? json['postedBy']['avatar'];
      }
    } else {
      if (json['avatar'] != null && (json['avatar'] as String).isNotEmpty) {
        avatarUrl = ApiConstants.resolveImageUrl(json['avatar']) ?? json['avatar'];
      }
      helperName = json['name'] ?? 'Helper';
    }

    final bio = json['description'] as String?;
    final address = json['address'] as String?;

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
      description: bio ?? 'Professional helper in your area',
      distance: address ?? 'Nearby',
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
    );
  }

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
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

  PopularService({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.pricePerHour,
    required this.distance,
    required this.image,
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
  });

  factory HelperProfileData.fromJson(Map<String, dynamic> json) {
    String categoryName = 'General';
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
              ?.map((e) => ApiConstants.resolveImageUrl(e as String) ?? (e as String))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
