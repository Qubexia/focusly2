class SubjectProgressModel {
  final int progressPercent;
  final int chaptersTotal;
  final int chaptersCompleted;

  const SubjectProgressModel({
    required this.progressPercent,
    required this.chaptersTotal,
    required this.chaptersCompleted,
  });

  factory SubjectProgressModel.fromJson(Map<String, dynamic> json) {
    return SubjectProgressModel(
      progressPercent: _asInt(json['progressPercent'], fallback: 0),
      chaptersTotal: _asInt(json['chaptersTotal'], fallback: 0),
      chaptersCompleted: _asInt(json['chaptersCompleted'], fallback: 0),
    );
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}
