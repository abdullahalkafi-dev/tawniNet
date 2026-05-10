import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AwnneaSearchController extends GetxController {
  final searchController = TextEditingController();
  final isSearching = false.obs;
  
  final recentSearches = [
    'Cleaning Services',
    'Water Faucet Repairing',
    'Barber Services',
    'Michael Chen',
    'Window Cleaning',
    'House Shifting',
    'Floor Wash',
  ].obs;

  void onSearch(String query) {
    if (query.isNotEmpty) {
      isSearching.value = true;
    }
  }

  void clearRecent() {
    recentSearches.clear();
  }

  void removeRecent(String item) {
    recentSearches.remove(item);
  }
}
