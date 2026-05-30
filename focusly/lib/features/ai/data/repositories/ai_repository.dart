import '../datasources/ai_remote_datasource.dart';
import '../models/ai_artifact_model.dart';

class AiRepository {
  AiRepository({AiRemoteDataSource? remote})
      : _remote = remote ?? AiRemoteDataSource();

  final AiRemoteDataSource _remote;

  Future<String> submitJob({
    required List<String> imageKeys,
    String? subjectId,
  }) async {
    final result = await _remote.submitJob(
      imageKeys: imageKeys,
      subjectId: subjectId,
    );
    return (result['jobId'] ?? result['id'] ?? '').toString();
  }

  Future<AiJobModel> getJob(String id) => _remote.getJob(id);

  Future<List<AiArtifactModel>> getArtifacts({required String subjectId}) {
    return _remote.getArtifacts(subjectId: subjectId);
  }
}
