class AnalyticsSubjectModel {
  final String subjectId;
  final String subjectName;
  final String? color;
  final int focusMinutes;

  const AnalyticsSubjectModel({
    required this.subjectId,
    required this.subjectName,
    this.color,
    required this.focusMinutes,
  });

  factory AnalyticsSubjectModel.fromJson(Map<String, dynamic> json) {
    return AnalyticsSubjectModel(
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? 'Unknown',
      color: json['color'] as String?,
      focusMinutes: json['focusMinutes'] as int? ?? 0,
    );
  }
}
