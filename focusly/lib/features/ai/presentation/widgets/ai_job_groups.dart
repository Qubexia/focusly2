import '../../data/models/ai_artifact_model.dart';

class AiJobGroup {
  const AiJobGroup({
    required this.jobId,
    required this.artifacts,
    this.createdAt,
  });

  final String jobId;
  final List<AiArtifactModel> artifacts;
  final DateTime? createdAt;

  AiArtifactModel? get summary {
    for (final a in artifacts) {
      if (a.kind == 'summary') return a;
    }
    return artifacts.isNotEmpty ? artifacts.first : null;
  }

  String get preview {
    final text = summary?.summaryText ?? '';
    if (text.isNotEmpty) return text;
    final cardCount = artifacts
        .where((a) => a.kind == 'flashcards')
        .fold<int>(0, (n, a) => n + a.flashcards.length);
    final qCount = artifacts
        .where((a) => a.kind == 'questions')
        .fold<int>(0, (n, a) => n + a.questions.length);
    return '$cardCount flashcards · $qCount questions';
  }
}

List<AiJobGroup> groupArtifactsByJob(List<AiArtifactModel> artifacts) {
  final map = <String, List<AiArtifactModel>>{};
  for (final artifact in artifacts) {
    final id = artifact.jobId.isNotEmpty ? artifact.jobId : artifact.id;
    map.putIfAbsent(id, () => []).add(artifact);
  }

  final groups = map.entries
      .map(
        (e) => AiJobGroup(
          jobId: e.key,
          artifacts: e.value,
          createdAt: e.value
              .map((a) => a.createdAt)
              .whereType<DateTime>()
              .fold<DateTime?>(null, (latest, dt) {
            if (latest == null || dt.isAfter(latest)) return dt;
            return latest;
          }),
        ),
      )
      .toList();

  groups.sort((a, b) {
    final at = a.createdAt;
    final bt = b.createdAt;
    if (at == null && bt == null) return 0;
    if (at == null) return 1;
    if (bt == null) return -1;
    return bt.compareTo(at);
  });

  return groups;
}
