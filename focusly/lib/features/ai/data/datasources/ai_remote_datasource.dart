import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/ai_artifact_model.dart';

class AiRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> submitJob({
    List<String> imageKeys = const [],
    List<String> pdfKeys = const [],
    String? subjectId,
    String? chapterId,
    String? language,
    String? detailLevel,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.aiNotesJobs,
      data: {
        if (imageKeys.isNotEmpty) 'imageKeys': imageKeys,
        if (pdfKeys.isNotEmpty) 'pdfKeys': pdfKeys,
        if (subjectId != null) 'subjectId': subjectId,
        if (chapterId != null) 'chapterId': chapterId,
        if (language != null) 'language': language,
        if (detailLevel != null) 'detailLevel': detailLevel,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<AiJobModel> getJob(String id) async {
    final response = await _dio.get(ApiEndpoints.aiNotesJobById(id));
    return AiJobModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AiArtifactModel>> getArtifacts({
    String? subjectId,
    String? chapterId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.aiArtifacts,
      queryParameters: {
        if (subjectId != null) 'subjectId': subjectId,
        if (chapterId != null) 'chapterId': chapterId,
      },
    );
    final data = response.data as List<dynamic>;
    return data
        .map(
          (item) => AiArtifactModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
