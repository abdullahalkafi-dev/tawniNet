import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:awnneaapp/app/services/auth_service.dart';
import 'package:awnneaapp/app/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    if (!authService.isLoggedIn.value) {
      return const RouteSettings(name: Routes.roleSelection);
    }

    return null; // allow navigation
  }
}
