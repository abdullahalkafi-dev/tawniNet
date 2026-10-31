import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../values/app_colors.dart';
import '../../services/api_client.dart';

class AppSnackbar {
  AppSnackbar._();

  /// Parse any error (ApiException, DioException, Exception, String) into a clean, human-readable message.
  static String extractErrorMessage(dynamic error) {
    if (error == null) return 'err_http_unknown'.tr;

    // 1. ApiException from ApiClient
    if (error is ApiException) {
      return error.displayMessage;
    }

    // 2. DioException directly
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'ui_connection_timed_out_please_check_your_internet'.tr;
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'ui_cannot_connect_to_server_please_check_your'.tr;
      }

      final response = error.response;
      if (response?.data is Map) {
        final data = response!.data as Map<String, dynamic>;

        // Try errorSources
        final errorSources = data['errorSources'];
        if (errorSources is List && errorSources.isNotEmpty) {
          final first = errorSources.first;
          if (first is Map && first['message'] != null) {
            final msg = first['message'].toString().trim();
            if (msg.isNotEmpty) return msg;
          }
        }

        // Try message field
        if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
          return data['message'].toString().trim();
        }
      }

      if (response?.statusCode == 401) {
        return 'ui_invalid_phone_number_or_password'.tr;
      } else if (response?.statusCode == 403) {
        return 'ui_access_forbidden'.tr;
      } else if (response?.statusCode == 404) {
        return 'ui_resource_not_found'.tr;
      } else if (response?.statusCode != null && response!.statusCode! >= 500) {
        return 'ui_server_error_please_try_again_later'.tr;
      }

      return error.message ?? 'ui_an_unexpected_network_error_occurred'.tr;
    }

    final str = error.toString().trim();

    // 3. Fallback: If it's a serialized DioException string
    if (str.contains('DioException') || str.contains('validateStatus')) {
      if (str.contains('401')) return 'err_http_401'.tr;
      if (str.contains('403')) return 'err_http_403'.tr;
      if (str.contains('404')) return 'err_http_404'.tr;
      if (str.contains('500') || str.contains('502') || str.contains('503')) {
        return 'ui_server_error_please_try_again_later'.tr;
      }
      return 'ui_network_request_failed_please_try_again'.tr;
    }

    return str
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^ApiException:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '')
        .trim();
  }

  /// Show a beautifully styled Error Snackbar
  static void showError(dynamic error, {String? title}) {
    final message = extractErrorMessage(error);

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      titleText: Text(
        title ?? 'ui_error'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.3,
        ),
      ),
      icon: const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
        size: 26,
      ),
      backgroundColor: const Color(0xFFE53935),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Show a beautifully styled Success Snackbar
  static void showSuccess(String message, {String? title}) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      titleText: Text(
        title ?? 'booking_success'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1.3,
        ),
      ),
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.white,
        size: 26,
      ),
      backgroundColor: AppColors.primary,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
