class AiArtifactModel {
  const AiArtifactModel({
    required this.id,
    required this.subjectId,
    required this.jobId,
    required this.kind,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String subjectId;
  final String jobId;
  final String kind;
  final Map<String, dynamic> content;
  final DateTime? createdAt;

  factory AiArtifactModel.fromJson(Map<String, dynamic> json) {
    return AiArtifactModel(
      id: _id(json['id'] ?? json['_id']),
      subjectId: _id(json['subjectId']),
      jobId: _id(json['jobId']),
      kind: (json['kind'] as String?) ?? 'summary',
      content: (json['content'] as Map<String, dynamic>?) ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  String get summaryText {
    final text = content['text'] ?? content['summary'] ?? content['body'];
    return text?.toString() ?? '';
  }

  List<Map<String, dynamic>> get flashcards {
    final raw = content['cards'] ?? content['flashcards'] ?? content['items'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> get questions {
    final raw = content['questions'] ?? content['items'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  static String _id(dynamic value) => value?.toString() ?? '';
}

class AiJobModel {
  const AiJobModel({
    required this.id,
    required this.status,
    this.failureReason,
    this.subjectId,
  });

  final String id;
  final String status;
  final String? failureReason;
  final String? subjectId;

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing =>
      status == 'processing' || status == 'queued';

  factory AiJobModel.fromJson(Map<String, dynamic> json) {
    return AiJobModel(
      id: _id(json['id'] ?? json['_id'] ?? json['jobId']),
      status: (json['status'] as String?) ?? 'queued',
      failureReason: json['failureReason'] as String?,
      subjectId: json['subjectId']?.toString(),
    );
  }

  static String _id(dynamic value) => value?.toString() ?? '';
}
