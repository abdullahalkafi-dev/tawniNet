import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final IconData icon;
  final Color color;

  Category({required this.id, required this.name, this.iconUrl, required this.icon, required this.color});

  /// Rewrites localhost URLs to work on real device
  String? get resolvedIconUrl {
    if (iconUrl == null || iconUrl!.isEmpty) return null;
    // Replace localhost with device IP for real device access
    return iconUrl!.replaceAll('localhost', '192.168.0.198');
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? '';
    final mapping = _categoryMapping[name];
    return Category(
      id: json['_id'] ?? '',
      name: name,
      iconUrl: json['icon'],
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

  HelperJob({
    required this.id,
    required this.helperName,
    required this.helperImage,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.description,
    required this.distance,
    String? name,
    this.avatar,
    this.bio,
    this.address,
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
    if (json['postedBy'] is Map) {
      helperName = json['postedBy']['name'] ?? 'Helper';
      if (json['postedBy']['avatar'] != null && (json['postedBy']['avatar'] as String).isNotEmpty) {
        avatarUrl = json['postedBy']['avatar'];
      }
    } else {
      if (json['avatar'] != null && (json['avatar'] as String).isNotEmpty) {
        avatarUrl = json['avatar'];
      }
      helperName = json['name'] ?? 'Helper';
    }

    final bio = json['description'] as String?;
    final address = json['address'] as String?;

    return HelperJob(
      id: json['_id'] ?? '',
      helperName: helperName,
      helperImage: avatarUrl,
      timeAgo: _formatDate(json['createdAt']),
      category: category,
      title: json['title'] ?? 'Available for hire',
      description: bio ?? 'Professional helper in your area',
      distance: address ?? 'Nearby',
      name: helperName,
      avatar: avatarUrl,
      bio: bio,
      address: address,
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
