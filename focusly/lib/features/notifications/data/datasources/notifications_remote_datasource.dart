import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_inbox_model.dart';

class NotificationsRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<List<NotificationInboxModel>> getNotifications({
    int limit = 50,
    String? cursor,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response.data;
    final List<dynamic> items;
    if (data is List<dynamic>) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      items = (data['data'] ?? data['items'] ?? const []) as List<dynamic>;
    } else {
      items = const [];
    }

    return items
        .map(
          (item) => NotificationInboxModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch(ApiEndpoints.notificationRead(id));
  }

  Future<void> markAllRead() async {
    await _dio.post(ApiEndpoints.notificationsReadAll);
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete(ApiEndpoints.notificationById(id));
  }
}
