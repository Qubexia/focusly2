class ChapterModel {
  final String id;
  final String subjectId;
  final String title;
  final int order;
  final bool completed;
  final DateTime? completedAt;

  const ChapterModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
    required this.completed,
    this.completedAt,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      subjectId: (json['subjectId'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      order: (json['order'] ?? 0) as int,
      completed: (json['completed'] ?? false) as bool,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
