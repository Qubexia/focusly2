import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

/// Configures the global Dio instance with auth interceptor,
/// auto-refresh on 401, and error normalization.
class ApiClient {
  static Dio? _dio;

  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio));
    
    // Add a simple logger for debugging
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('🌐 DIO [${options.method}] → ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ DIO [${response.requestOptions.method}] ← ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (err, handler) {
        final status = err.response?.statusCode;
        debugPrint('❌ DIO [${err.requestOptions.method}] ERROR ${status ?? ''}: ${err.message}');
        debugPrint('🔗 URL: ${err.requestOptions.uri}');
        if (err.requestOptions.data != null) {
          debugPrint('📤 REQUEST BODY: ${err.requestOptions.data}');
        }
        if (err.response?.data != null) {
          debugPrint('📥 RESPONSE BODY: ${err.response?.data}');
        }
        return handler.next(err);
      },
    ));

    return dio;
  }

  /// Reset the singleton (useful after logout).
  static void reset() {
    _dio?.close();
    _dio = null;
  }
}

/// Interceptor that:
/// 1. Attaches Bearer token to every request
/// 2. On 401: attempts token refresh, retries original request
/// 3. On 403 PREMIUM_REQUIRED: refreshes JWT (updates plan claim) and retries once
/// 4. On refresh failure after 401: clears tokens
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    final publicPaths = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.googleLogin,
      ApiEndpoints.forgotPassword,
      ApiEndpoints.resetPassword,
      ApiEndpoints.verifyEmail,
    ];

    if (!publicPaths.contains(options.path)) {
      final token = await SecureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final resolved = await _refreshAndRetry(err, handler);
      if (resolved) return;
    }

    if (err.response?.statusCode == 403 &&
        _isPremiumRequired(err) &&
        err.requestOptions.extra['premiumRetried'] != true) {
      final resolved = await _refreshAndRetry(
        err,
        handler,
        markPremiumRetried: true,
      );
      if (resolved) return;
    }

    handler.next(err);
  }

  bool _isPremiumRequired(DioException err) {
    final data = err.response?.data;
    if (data is! Map<String, dynamic>) return false;
    return data['code'] == 'PREMIUM_REQUIRED';
  }

  Future<bool> _refreshAndRetry(
    DioException err,
    ErrorInterceptorHandler handler, {
    bool markPremiumRetried = false,
  }) async {
    if (_isRefreshing) return false;

    _isRefreshing = true;
    try {
      final refreshed = await _attemptRefresh();
      if (!refreshed) return false;

      final token = await SecureStorage.getAccessToken();
      final retryOptions = err.requestOptions;
      if (markPremiumRetried) {
        retryOptions.extra['premiumRetried'] = true;
      }
      retryOptions.headers['Authorization'] = 'Bearer $token';
      if (retryOptions.data is FormData) {
        retryOptions.data = (retryOptions.data as FormData).clone();
      }
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
      return true;
    } catch (_) {
      if (err.response?.statusCode == 401) {
        await SecureStorage.clearTokens();
      }
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> _attemptRefresh() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    final deviceId = await SecureStorage.getDeviceId();
    if (refreshToken == null || deviceId == null) return false;

    try {
      final freshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await freshDio.post(
        ApiEndpoints.refresh,
        data: {
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $refreshToken'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      await SecureStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
