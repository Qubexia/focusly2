import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/analytics_summary_model.dart';
import '../models/analytics_subject_model.dart';

class AnalyticsRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<AnalyticsSummaryModel> getSummary({String? from, String? to}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsSummary,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );

    return AnalyticsSummaryModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AnalyticsSubjectModel>> getBySubject({String? from, String? to}) async {
    final response = await _dio.get(
      ApiEndpoints.analyticsBySubject,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      },
    );

    final data = response.data as List<dynamic>;
    return data
        .map((e) => AnalyticsSubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
