import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/data/models/api_response.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  /// Stable machine-readable code sent by the server (e.g. INSUFFICIENT_BALANCE).
  /// Used to show a message in the user's own language.
  final String? code;

  /// Values to substitute into the translated message (e.g. {required: 60}).
  final Map<String, dynamic>? params;

  /// True when the request never reached the server (offline / timeout).
  final bool isNetworkError;

  ApiException(
    this.message, {
    this.statusCode,
    this.data,
    this.code,
    this.params,
    this.isNetworkError = false,
  });

  /// The message to show: a translated one when the server sent a known code,
  /// otherwise the server's own text.
  String get displayMessage {
    final c = code;
    if (c != null && c.isNotEmpty) {
      final key = 'err_${c.toLowerCase()}';
      final translated = key.tr;
      if (translated != key) {
        var text = translated;
        params?.forEach((k, v) {
          final shown = v is num && v == v.roundToDouble() ? v.toInt().toString() : v.toString();
          text = text.replaceAll('@$k', shown);
        });
        return text;
      }
    }
    return message;
  }

  @override
  String toString() => displayMessage;
}

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;

  // Callback when the session is definitively over — set by AuthService to force logout
  Function()? onAuthFailed;

  /// Called after a refresh succeeds so other parts (e.g. sockets) can pick up the new token.
  void Function(String accessToken)? onTokenRefreshed;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(_storage));
    _dio.interceptors.add(_TokenRefreshInterceptor(_storage, this));
    if (kDebugMode) {
      // Only the URL and status are logged — never headers or bodies (they carry tokens / passwords / OTPs).
      _dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (o) => debugPrint('[API] $o'),
        ),
      );
    }
  }

  Dio get dio => _dio;
  Dio get client => _dio;

  // ─── Convenience Methods ────────────────────────────────

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.delete(path, data: data, queryParameters: queryParameters);
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required FormData formData,
    T Function(dynamic)? fromData,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          contentType: 'multipart/form-data',
          // Uploads (photos / video) can take longer than normal calls.
          sendTimeout: const Duration(minutes: 3),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic)? fromData,
  ) {
    if (response.data is Map<String, dynamic>) {
      final json = response.data as Map<String, dynamic>;
      return ApiResponse.fromJson(json, fromData);
    }
    return ApiResponse<T>(success: true, data: null);
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        'ui_connection_timed_out_please_check_your_internet'.tr,
        isNetworkError: true,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        'ui_cannot_connect_to_server_please_check_your'.tr,
        isNetworkError: true,
      );
    }

    final response = error.response;
    if (response?.data is Map) {
      final data = Map<String, dynamic>.from(response!.data as Map);
      final code = data['code']?.toString();
      final params = data['params'] is Map
          ? Map<String, dynamic>.from(data['params'] as Map)
          : null;

      // 1. Try errorSources array from backend AppError
      final errorSources = data['errorSources'];
      if (errorSources is List && errorSources.isNotEmpty) {
        final first = errorSources.first;
        if (first is Map && first['message'] != null) {
          final msg = first['message'].toString().trim();
          if (msg.isNotEmpty) {
            return ApiException(msg,
                statusCode: response.statusCode, data: data, code: code, params: params);
          }
        }
      }

      // 2. Try message field
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return ApiException(data['message'].toString().trim(),
            statusCode: response.statusCode, data: data, code: code, params: params);
      }
    }

    // Default friendly fallback messages based on status codes
    final status = response?.statusCode;
    if (status == 401) {
      return ApiException('err_http_401'.tr, statusCode: 401);
    } else if (status == 403) {
      return ApiException('err_http_403'.tr, statusCode: 403);
    } else if (status == 404) {
      return ApiException('err_http_404'.tr, statusCode: 404);
    } else if (status == 409) {
      return ApiException('err_http_409'.tr, statusCode: 409);
    } else if (status == 429) {
      return ApiException('err_http_429'.tr, statusCode: 429);
    } else if (status != null && status >= 500) {
      return ApiException('err_http_500'.tr, statusCode: status);
    }

    return ApiException(
      'err_http_unknown'.tr,
      isNetworkError: error.type == DioExceptionType.unknown,
    );
  }
}

// ─── Auth Interceptor ───────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  final StorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Tell the server which language to answer in.
    try {
      final lang = Get.locale?.languageCode;
      if (lang != null) options.headers['Accept-Language'] = lang;
    } catch (_) {}

    // Skip token for auth routes that are public (login / otp / refresh).
    // Logout and change-password need the bearer.
    final p = options.path;
    final needsBearer = p.startsWith('/auth/logout') || p.startsWith('/auth/change-password');
    if (p.startsWith('/auth/') && !needsBearer) {
      return handler.next(options);
    }

    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─── Token Refresh Interceptor ──────────────────────────────

/// On a 401 the access token is renewed exactly once, no matter how many
/// requests failed at the same time; every waiting request is then replayed
/// with the new token. The user is only logged out when the server really
/// rejects the refresh token — a flaky network never ends the session.
class _TokenRefreshInterceptor extends Interceptor {
  final StorageService _storage;
  final ApiClient _client;
  Future<String?>? _refreshing;

  _TokenRefreshInterceptor(this._storage, this._client);

  bool _isAuthPath(String path) =>
      path.startsWith('/auth/') &&
      !path.startsWith('/auth/logout') &&
      !path.startsWith('/auth/change-password');

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    if (_isAuthPath(path) || err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // A request already retried once with a fresh token must not loop.
    if (err.requestOptions.extra['__retried'] == true) {
      return handler.next(err);
    }

    final sentWith = err.requestOptions.headers['Authorization']?.toString();

    try {
      // If another request already refreshed while this one was in flight, just replay it.
      final current = await _storage.getAccessToken();
      String? token;
      if (current != null && sentWith != null && sentWith != 'Bearer $current') {
        token = current;
      } else {
        token = await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
      }

      if (token == null) {
        // Refresh was not possible for a temporary reason (offline): keep the session, fail this call.
        return handler.next(err);
      }

      err.requestOptions.headers['Authorization'] = 'Bearer $token';
      err.requestOptions.extra['__retried'] = true;
      final retry = await _client.dio.fetch(err.requestOptions);
      return handler.resolve(retry);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }

  /// Returns the new access token, or null when the session must be kept
  /// (temporary network problem). Calls [ApiClient.onAuthFailed] only when the
  /// server definitively refuses the refresh token.
  Future<String?> _refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _client.onAuthFailed?.call();
      return null;
    }

    try {
      final response = await Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeoutMs),
          receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        ),
      ).post(
        '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
        data: {'refreshToken': refreshToken},
      );

      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = body['data'] as Map;
        final access = data['accessToken']?.toString();
        // The server rotates the refresh token: always keep the newest one.
        final newRefresh = data['refreshToken']?.toString() ?? refreshToken;
        if (access != null && access.isNotEmpty) {
          await _storage.saveTokens(accessToken: access, refreshToken: newRefresh);
          _client.onTokenRefreshed?.call(access);
          return access;
        }
      }
      _client.onAuthFailed?.call();
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403 || status == 404) {
        _client.onAuthFailed?.call();
      }
      // Timeouts, no connection, 5xx, 429: keep the user signed in.
      return null;
    } catch (_) {
      return null;
    }
  }
}
