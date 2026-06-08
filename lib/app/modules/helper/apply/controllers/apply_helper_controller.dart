import 'package:awnneaapp/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApplyHelperController extends GetxController {
  final fullNameController = TextEditingController();
  final ageController = TextEditingController();
  final cityController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();
  final experienceController = TextEditingController();
  final serviceRadiusController = TextEditingController();
  final bioController = TextEditingController();

  final selectedLanguage = 'English'.obs;
  final selectedServiceType = ''.obs;
  final selectedIdType = 'NID'.obs;
  final hasDocument = false.obs;

  final languages = ['English', 'Morocco'].obs;
  final serviceTypes = [
    'Cleaning Service',
    'Shifting Service',
    'Electrician Service',
    'Plumber Service',
    'Painting Service',
    'Moving',
    'Garden',
    'Mechanic Service',
    'Laundry',
    'Others',
  ].obs;
  final idTypes = ['NID', 'Passport', 'Driving License'].obs;

  void submitApplication() {
    Get.toNamed(Routes.applicationPending);
  }

  void updateAndReapply() {
    Get.back();
  }

  void logout() {
    Get.offAllNamed(Routes.login, arguments: {'role': 'helper'});
  }

  @override
  void onClose() {
    fullNameController.dispose();
    ageController.dispose();
    cityController.dispose();
    phoneController.dispose();
    emailController.dispose();
    locationController.dispose();
    priceController.dispose();
    experienceController.dispose();
    serviceRadiusController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
