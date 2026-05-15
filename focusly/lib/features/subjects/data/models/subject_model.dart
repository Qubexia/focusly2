class SubjectModel {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final int dailyTargetMinutes;
  final int progressPercent;
  final bool isArchived;

  const SubjectModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.dailyTargetMinutes,
    required this.progressPercent,
    required this.isArchived,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      dailyTargetMinutes: (json['dailyTargetMinutes'] ?? 0) as int,
      progressPercent: (json['progressPercent'] ?? 0) as int,
      isArchived: (json['isArchived'] ?? false) as bool,
    );
  }
}
