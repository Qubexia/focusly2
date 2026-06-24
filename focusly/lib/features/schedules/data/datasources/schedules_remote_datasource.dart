import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/schedule_model.dart';

class SchedulesRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  int _uiWeekdayToApiWeekday(int weekday) {
    return weekday % 7;
  }

  Future<List<StudyScheduleModel>> getSchedules({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.schedules,
      queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      },
    );

    final data = response.data as List<dynamic>;
    return data
        .map((item) => StudyScheduleModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StudyScheduleModel> createSchedule({
    required String subjectId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    required List<int> daysOfWeek,
    int reminderMinutesBefore = 15,
    bool reminderEnabled = true,
  }) async {
    // Note: The backend endpoint is POST /v1/subjects/:subjectId/schedules
    final endpoint = '/v1/subjects/$subjectId/schedules';
    final response = await _dio.post(
      endpoint,
      data: {
        'title': title,
        'startAt': startAt.toIso8601String(),
        if (endAt != null) 'endAt': endAt.toIso8601String(),
        'daysOfWeek': daysOfWeek.map(_uiWeekdayToApiWeekday).toList(),
        'reminderMinutesBefore': reminderMinutesBefore,
        'reminderEnabled': reminderEnabled,
      },
    );

    return StudyScheduleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudyScheduleModel> updateSchedule({
    required String id,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    List<int>? daysOfWeek,
    int? reminderMinutesBefore,
    bool? reminderEnabled,
    bool? isActive,
  }) async {
    final response = await _dio.patch(
      ApiEndpoints.scheduleById(id),
      data: {
        if (title != null) 'title': title,
        if (startAt != null) 'startAt': startAt.toIso8601String(),
        if (endAt != null) 'endAt': endAt.toIso8601String(),
        if (daysOfWeek != null)
          'daysOfWeek': daysOfWeek.map(_uiWeekdayToApiWeekday).toList(),
        if (reminderMinutesBefore != null)
          'reminderMinutesBefore': reminderMinutesBefore,
        if (reminderEnabled != null) 'reminderEnabled': reminderEnabled,
        if (isActive != null) 'isActive': isActive,
      },
    );

    return StudyScheduleModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete(ApiEndpoints.scheduleById(id));
  }

  /// Marks a single occurrence (by local 'YYYY-MM-DD' date) of a schedule done.
  Future<void> completeSchedule({
    required String id,
    required String date,
  }) async {
    await _dio.post(
      ApiEndpoints.scheduleComplete(id),
      data: {'date': date},
    );
  }

  /// Returns completed occurrences in a date range as `scheduleId|date` keys.
  Future<Set<String>> getCompletions({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.schedulesCompletions,
      queryParameters: {
        'from': _formatDate(from),
        'to': _formatDate(to),
      },
    );

    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((item) {
          final map = item as Map<String, dynamic>;
          return '${map['scheduleId']}|${map['date']}';
        })
        .toSet();
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
