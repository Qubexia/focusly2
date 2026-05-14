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
/// 3. On refresh failure: clears tokens
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
      _isRefreshing = true;
      try {
        final refreshed = await _attemptRefresh();
        if (refreshed) {
          // Retry the original request with new token
          final token = await SecureStorage.getAccessToken();
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(retryOptions);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh failed — clear tokens
        await SecureStorage.clearTokens();
      }
      _isRefreshing = false;
    }
    handler.next(err);
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
