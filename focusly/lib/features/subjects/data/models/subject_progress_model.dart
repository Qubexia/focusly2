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
      progressPercent: (json['progressPercent'] ?? 0) as int,
      chaptersTotal: (json['chaptersTotal'] ?? 0) as int,
      chaptersCompleted: (json['chaptersCompleted'] ?? 0) as int,
    );
  }
}
