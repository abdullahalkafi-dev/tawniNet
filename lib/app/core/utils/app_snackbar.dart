import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../values/app_colors.dart';
import '../../services/api_client.dart';

class AppSnackbar {
  AppSnackbar._();

  /// Parse any error (ApiException, DioException, Exception, String) into a clean, human-readable message.
  static String extractErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred';

    // 1. ApiException from ApiClient
    if (error is ApiException) {
      return error.message;
    }

    // 2. DioException directly
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Cannot connect to server. Please check your network.';
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
        return 'Invalid phone number or password';
      } else if (response?.statusCode == 403) {
        return 'Access forbidden';
      } else if (response?.statusCode == 404) {
        return 'Resource not found';
      } else if (response?.statusCode != null && response!.statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }

      return error.message ?? 'An unexpected network error occurred';
    }

    final str = error.toString().trim();

    // 3. Fallback: If it's a serialized DioException string
    if (str.contains('DioException') || str.contains('validateStatus')) {
      if (str.contains('401')) return 'Invalid phone number or password';
      if (str.contains('403')) return 'Access denied';
      if (str.contains('404')) return 'Resource not found';
      if (str.contains('500') || str.contains('502') || str.contains('503')) {
        return 'Server error. Please try again later.';
      }
      return 'Network request failed. Please try again.';
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
        title ?? 'Error',
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
          color: Colors.black.withOpacity(0.15),
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
        title ?? 'Success',
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
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
