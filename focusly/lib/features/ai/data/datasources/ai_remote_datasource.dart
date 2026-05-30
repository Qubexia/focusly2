import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/ai_artifact_model.dart';

class AiRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> submitJob({
    required List<String> imageKeys,
    String? subjectId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.aiNotesJobs,
      data: {
        'imageKeys': imageKeys,
        if (subjectId != null) 'subjectId': subjectId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<AiJobModel> getJob(String id) async {
    final response = await _dio.get(ApiEndpoints.aiNotesJobById(id));
    return AiJobModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AiArtifactModel>> getArtifacts({required String subjectId}) async {
    final response = await _dio.get(
      ApiEndpoints.aiArtifacts,
      queryParameters: {'subjectId': subjectId},
    );
    final data = response.data as List<dynamic>;
    return data
        .map(
          (item) => AiArtifactModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
