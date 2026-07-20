import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/planned_item_model.dart';

class PlannerRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<List<PlannedItemModel>> getItems({
    required PlannedItemType type,
    String? from,
    String? to,
    String? subjectId,
  }) async {
    final endpoint = _getEndpoint(type);
    final response = await _dio.get(
      endpoint,
      queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (subjectId != null) 'subjectId': subjectId,
      },
    );

    final data = response.data as List<dynamic>;
    return data
        .map((item) => PlannedItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PlannedItemModel> createItem({
    required PlannedItemType type,
    required String title,
    String? notes,
    required String plannedAt,
    String? subjectId,
    int? reminderMinutesBefore,
    bool reminderEnabled = true,
    String? recurrence,
    List<int>? daysOfWeek,
    String? recurrenceEndAt,
  }) async {
    final endpoint = _getEndpoint(type);
    final response = await _dio.post(
      endpoint,
      data: {
        'title': title,
        if (notes != null) 'notes': notes,
        'plannedAt': plannedAt,
        if (subjectId != null) 'subjectId': subjectId,
        if (recurrence != null) 'recurrence': recurrence,
        if (daysOfWeek != null && daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
        if (recurrenceEndAt != null) 'recurrenceEndAt': recurrenceEndAt,
        'reminderEnabled': reminderEnabled,
        if (reminderEnabled && reminderMinutesBefore != null)
          'reminderMinutesBefore': reminderMinutesBefore,
      },
    );

    return PlannedItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlannedItemModel> updateItem({
    required PlannedItemType type,
    required String id,
    String? title,
    String? notes,
    String? plannedAt,
    String? subjectId,
    bool? completed,
  }) async {
    final endpoint = _getByIdEndpoint(type, id);
    final response = await _dio.patch(
      endpoint,
      data: {
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
        if (plannedAt != null) 'plannedAt': plannedAt,
        if (subjectId != null) 'subjectId': subjectId,
        if (completed != null) 'completed': completed,
      },
    );

    return PlannedItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PlannedItemModel> completeItem({
    required PlannedItemType type,
    required String id,
    String? occurrenceDate,
  }) async {
    final endpoint = _getCompleteEndpoint(type, id);
    final response = await _dio.post(
      endpoint,
      // Recurring items are completed one day at a time; the server keys the
      // tick by the date the client actually rendered.
      queryParameters: {
        if (occurrenceDate != null) 'date': occurrenceDate,
      },
    );
    return PlannedItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteItem({
    required PlannedItemType type,
    required String id,
  }) async {
    final endpoint = _getByIdEndpoint(type, id);
    await _dio.delete(endpoint);
  }

  String _getEndpoint(PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return ApiEndpoints.tasks;
      case PlannedItemType.revision:
        return ApiEndpoints.revisions;
      case PlannedItemType.lecture:
        return ApiEndpoints.lectures;
      case PlannedItemType.exam:
        return ApiEndpoints.exams;
    }
  }

  String _getByIdEndpoint(PlannedItemType type, String id) {
    switch (type) {
      case PlannedItemType.task:
        return ApiEndpoints.taskById(id);
      case PlannedItemType.revision:
        return ApiEndpoints.revisionById(id);
      case PlannedItemType.lecture:
        return ApiEndpoints.lectureById(id);
      case PlannedItemType.exam:
        return ApiEndpoints.examById(id);
    }
  }

  String _getCompleteEndpoint(PlannedItemType type, String id) {
    switch (type) {
      case PlannedItemType.task:
        return ApiEndpoints.taskComplete(id);
      case PlannedItemType.revision:
        return ApiEndpoints.revisionComplete(id);
      case PlannedItemType.lecture:
        return ApiEndpoints.lectureComplete(id);
      case PlannedItemType.exam:
        return ApiEndpoints.examComplete(id);
    }
  }
}
