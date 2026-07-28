import 'dart:async';

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

  /// Proactively refresh tokens (e.g. before a long focus session completes).
  ///
  /// This is the only entry point that may rotate the refresh token — see
  /// [_AuthInterceptor.refreshTokens].
  static Future<bool> refreshSessionTokensIfNeeded() async =>
      await _AuthInterceptor.refreshTokens() == RefreshOutcome.success;
}

/// Why a refresh attempt ended, because the two failures mean opposite things:
/// [rejected] is the server saying the session is gone, [unavailable] is the
/// network being unreachable while the session is still perfectly valid.
enum RefreshOutcome { success, rejected, unavailable }

/// Interceptor that:
/// 1. Attaches Bearer token to every request
/// 2. On 401: attempts token refresh, retries original request
/// 3. On 403 PREMIUM_REQUIRED: refreshes JWT (updates plan claim) and retries once
/// 4. On the server rejecting the refresh token: clears tokens. A refresh that
///    merely failed to reach the server leaves the session intact.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  static Completer<RefreshOutcome>? _refreshCompleter;

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
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['authRetried'] != true) {
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

  /// Single-flight refresh. The server rotates the refresh token on every call
  /// and treats a second use of the old one as a stolen token — it revokes the
  /// whole session family, which signs the user out for good. So two refreshes
  /// must never be in flight at once, and every caller in the app funnels
  /// through here.
  static Future<RefreshOutcome> refreshTokens() {
    final inFlight = _refreshCompleter;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<RefreshOutcome>();
    _refreshCompleter = completer;

    unawaited(() async {
      RefreshOutcome outcome;
      try {
        outcome = await _attemptRefresh();
      } catch (_) {
        outcome = RefreshOutcome.unavailable;
      }
      // Clear the slot before completing so a waiter that resumes immediately
      // starts a fresh attempt instead of reusing a completed completer.
      _refreshCompleter = null;
      completer.complete(outcome);
    }());

    return completer.future;
  }

  Future<bool> _refreshAndRetry(
    DioException err,
    ErrorInterceptorHandler handler, {
    bool markPremiumRetried = false,
  }) async {
    final outcome = await refreshTokens();
    if (outcome != RefreshOutcome.success) {
      // Only drop the session when the server itself rejected the refresh
      // token. Wiping tokens because the network was down would sign the user
      // out over a dropped connection.
      if (outcome == RefreshOutcome.rejected &&
          err.response?.statusCode == 401) {
        await SecureStorage.clearTokens();
      }
      return false;
    }

    try {
      final token = await SecureStorage.getAccessToken();
      final retryOptions = err.requestOptions;
      if (markPremiumRetried) {
        retryOptions.extra['premiumRetried'] = true;
      }
      // The retry runs through this interceptor again, so mark it to stop a
      // still-401 response from looping back into another refresh forever.
      retryOptions.extra['authRetried'] = true;
      retryOptions.headers['Authorization'] = 'Bearer $token';
      if (retryOptions.data is FormData) {
        retryOptions.data = (retryOptions.data as FormData).clone();
      }
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<RefreshOutcome> _attemptRefresh() async {
    final refreshToken = await SecureStorage.getRefreshToken();
    final deviceId = await SecureStorage.getDeviceId();
    if (refreshToken == null || deviceId == null) {
      return RefreshOutcome.rejected;
    }

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
      return RefreshOutcome.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      return status == 401 || status == 403
          ? RefreshOutcome.rejected
          : RefreshOutcome.unavailable;
    } catch (_) {
      return RefreshOutcome.unavailable;
    }
  }
}
