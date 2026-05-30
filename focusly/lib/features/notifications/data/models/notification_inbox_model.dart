import 'package:equatable/equatable.dart';

class NotificationInboxModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? type; // e.g., 'pomodoro', 'schedule', 'system'

  const NotificationInboxModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.type,
  });

  NotificationInboxModel copyWith({
    bool? isRead,
  }) {
    return NotificationInboxModel(
      id: id,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationInboxModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    final createdAtRaw = json['createdAt'];
    return NotificationInboxModel(
      id: id?.toString() ?? '',
      title: (json['title'] as String?) ?? 'Notification',
      body: (json['body'] as String?) ?? '',
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
      isRead: (json['isRead'] ?? json['read'] ?? false) as bool,
      type: json['type'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, body, createdAt, isRead, type];
}
