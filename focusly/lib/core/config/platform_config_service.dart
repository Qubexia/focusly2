import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import 'platform_config.dart';

class PlatformConfigService {
  PlatformConfigService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));

  final Dio _dio;

  Future<PlatformConfigData> fetch() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.config);
    final data = PlatformConfigData.fromJson(response.data ?? {});
    PlatformConfig.update(data);
    return data;
  }
}
