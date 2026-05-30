import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/pomodoro_session_model.dart';
import '../models/pomodoro_today_model.dart';

class PomodoroRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<PomodoroSessionModel> startSession({
    String? subjectId,
    required int focusMinutes,
    required int breakMinutes,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.pomodoroStart,
      data: {
        if (subjectId != null) 'subjectId': subjectId,
        'focusMinutes': focusMinutes,
        'breakMinutes': breakMinutes,
      },
    );

    return PomodoroSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PomodoroSessionModel> pauseSession(String id) async {
    final response = await _dio.post(ApiEndpoints.pomodoroPause(id));
    return PomodoroSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PomodoroSessionModel> resumeSession(String id) async {
    final response = await _dio.post(ApiEndpoints.pomodoroResume(id));
    return PomodoroSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PomodoroSessionModel> completeSession(String id) async {
    final response = await _dio.post(ApiEndpoints.pomodoroComplete(id));
    return PomodoroSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PomodoroSessionModel> abortSession(String id) async {
    final response = await _dio.post(ApiEndpoints.pomodoroAbort(id));
    return PomodoroSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PomodoroTodayModel> getToday() async {
    final response = await _dio.get(ApiEndpoints.pomodoroToday);
    return PomodoroTodayModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<PomodoroSessionModel>> getHistory({
    required String from,
    required String to,
    int limit = 50,
    String? cursor,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.pomodoroHistory,
      queryParameters: {
        'from': from,
        'to': to,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response.data;
    final List<dynamic> items;
    if (data is Map<String, dynamic>) {
      items = (data['data'] ?? const []) as List<dynamic>;
    } else if (data is List<dynamic>) {
      items = data;
    } else {
      items = const [];
    }

    return items
        .map(
          (item) =>
              PomodoroSessionModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
