import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:awnneaapp/app/core/constants/api_constants.dart';
import 'package:awnneaapp/app/services/storage_service.dart';
import 'package:awnneaapp/app/data/models/api_response.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;
  final StorageService _storage;

  // Callback when refresh token fails — set by AuthService to force logout
  Function()? onAuthFailed;

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
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
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
    T Function(dynamic)? fromData,
  }) async {
    try {
      final response = await _dio.delete(path);
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
        options: Options(contentType: 'multipart/form-data'),
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
      return ApiException('Connection timed out. Please check your internet connection.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return ApiException('Cannot connect to server. Please check your network.');
    }

    final response = error.response;
    if (response?.data is Map) {
      final data = response!.data as Map<String, dynamic>;

      // 1. Try errorSources array from backend AppError
      final errorSources = data['errorSources'];
      if (errorSources is List && errorSources.isNotEmpty) {
        final first = errorSources.first;
        if (first is Map && first['message'] != null) {
          final msg = first['message'].toString().trim();
          if (msg.isNotEmpty) {
            return ApiException(msg, statusCode: response.statusCode, data: data);
          }
        }
      }

      // 2. Try message field
      if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
        return ApiException(data['message'].toString().trim(), statusCode: response.statusCode, data: data);
      }
    }

    // Default friendly fallback messages based on status codes
    if (response?.statusCode == 401) {
      return ApiException('Invalid phone number or password', statusCode: 401);
    } else if (response?.statusCode == 403) {
      return ApiException('Access forbidden. Please contact support.', statusCode: 403);
    } else if (response?.statusCode == 404) {
      return ApiException('Resource not found', statusCode: 404);
    } else if (response?.statusCode == 409) {
      return ApiException('This record already exists.', statusCode: 409);
    } else if (response?.statusCode == 429) {
      return ApiException('Too many attempts. Please wait a moment.', statusCode: 429);
    } else if (response?.statusCode != null && response!.statusCode! >= 500) {
      return ApiException('Server error. Please try again later.', statusCode: response.statusCode);
    }

    return ApiException(error.message ?? 'An unexpected network error occurred');
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
    // Skip token for auth routes
    if (options.path.startsWith('/auth/')) {
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

class _TokenRefreshInterceptor extends Interceptor {
  final StorageService _storage;
  final ApiClient _client;
  bool _isRefreshing = false;

  _TokenRefreshInterceptor(this._storage, this._client);

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Never treat 401 on /auth/ endpoints (like login, verify-otp, etc.) as session expiry
    final path = err.requestOptions.path;
    if (path.startsWith('/auth/')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          _client.onAuthFailed?.call();
          return handler.next(err);
        }

        // Try to refresh
        final response = await Dio().post(
          '${ApiConstants.baseUrl}${ApiConstants.refreshToken}',
          data: {'refreshToken': refreshToken},
        );

        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final newAccessToken = data['data']['accessToken'] as String;
          await _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: refreshToken,
          );

          // Retry original request
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';
          final retryResponse = await _client.dio.fetch(err.requestOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (_) {
        // Refresh failed
      }

      _isRefreshing = false;
      _client.onAuthFailed?.call();
    }

    handler.next(err);
  }
}
