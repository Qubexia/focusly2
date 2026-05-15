import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/chapter_model.dart';
import '../models/subject_model.dart';
import '../models/subject_progress_model.dart';

class SubjectsRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<List<SubjectModel>> getSubjects({bool includeArchived = false}) async {
    final response = await _dio.get(
      ApiEndpoints.subjects,
      queryParameters: {
        if (includeArchived) 'includeArchived': 'true',
      },
    );

    final data = response.data as List<dynamic>;
    return data
        .map((item) => SubjectModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectModel> createSubject({
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.subjects,
      data: {
        'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        'dailyTargetMinutes': dailyTargetMinutes,
      },
    );

    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubjectModel> updateSubject({
    required String id,
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.subjectById(id),
      data: {
        'name': name,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        'dailyTargetMinutes': dailyTargetMinutes,
      },
    );

    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubjectModel> getSubjectById(String id) async {
    final response = await _dio.get(ApiEndpoints.subjectById(id));
    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubjectProgressModel> getSubjectProgress(String id) async {
    final response = await _dio.get(ApiEndpoints.subjectProgress(id));
    return SubjectProgressModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ChapterModel>> getSubjectChapters(String id) async {
    final response = await _dio.get(ApiEndpoints.subjectChapters(id));
    final data = response.data as List<dynamic>;
    return data
        .map((item) => ChapterModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChapterModel> createChapter({
    required String subjectId,
    required String title,
    int? order,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.subjectChapters(subjectId),
      data: {
        'title': title,
        if (order != null) 'order': order,
      },
    );

    return ChapterModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ChapterModel> updateChapter({
    required String subjectId,
    required String chapterId,
    String? title,
    int? order,
    bool? completed,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.subjectChapterById(subjectId, chapterId),
      data: {
        if (title != null) 'title': title,
        if (order != null) 'order': order,
        if (completed != null) 'completed': completed,
      },
    );

    return ChapterModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSubject(String id) async {
    await _dio.delete(ApiEndpoints.subjectById(id));
  }
}
