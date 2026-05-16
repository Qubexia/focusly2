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
    return NotificationInboxModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      type: json['type'],
    );
  }

  @override
  List<Object?> get props => [id, title, body, createdAt, isRead, type];
}
