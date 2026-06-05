import '../datasources/ai_remote_datasource.dart';
import '../models/ai_artifact_model.dart';

class AiRepository {
  AiRepository({AiRemoteDataSource? remote})
      : _remote = remote ?? AiRemoteDataSource();

  final AiRemoteDataSource _remote;

  Future<String> submitJob({
    List<String> imageKeys = const [],
    List<String> pdfKeys = const [],
    String? subjectId,
    String? chapterId,
    String? language,
    String? detailLevel,
  }) async {
    final result = await _remote.submitJob(
      imageKeys: imageKeys,
      pdfKeys: pdfKeys,
      subjectId: subjectId,
      chapterId: chapterId,
      language: language,
      detailLevel: detailLevel,
    );
    return (result['jobId'] ?? result['id'] ?? '').toString();
  }

  Future<AiJobModel> getJob(String id) => _remote.getJob(id);

  Future<List<AiArtifactModel>> getArtifacts({
    String? subjectId,
    String? chapterId,
  }) {
    return _remote.getArtifacts(subjectId: subjectId, chapterId: chapterId);
  }
}
