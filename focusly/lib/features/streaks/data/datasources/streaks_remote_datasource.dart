import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/streak_model.dart';

class StreaksRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<StreakModel> getMyStreak() async {
    final response = await _dio.get(ApiEndpoints.streaksMe);
    return StreakModel.fromJson(response.data as Map<String, dynamic>);
  }
}
