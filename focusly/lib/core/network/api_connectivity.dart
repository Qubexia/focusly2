import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';

class ApiConnectivity {
  ApiConnectivity._();

  static Future<bool> pingBackend({Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      final response = await dio.get('/v1/health');
      final ok = response.statusCode == 200;
      if (kDebugMode) {
        debugPrint(
          ok
              ? '✅ Backend reachable at ${ApiEndpoints.baseUrl}'
              : '⚠️ Backend HTTP ${response.statusCode} at ${ApiEndpoints.baseUrl}',
        );
      }
      return ok;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Backend unreachable at ${ApiEndpoints.baseUrl}: $e');
      }
      return false;
    }
  }
}
