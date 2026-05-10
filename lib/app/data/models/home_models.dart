import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  Category({required this.id, required this.name, required this.icon, required this.color});
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

  HelperJob({
    required this.id,
    required this.helperName,
    required this.helperImage,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.description,
    required this.distance,
  });
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
