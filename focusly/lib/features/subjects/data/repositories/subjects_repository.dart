import '../datasources/subjects_remote_datasource.dart';
import '../models/chapter_model.dart';
import '../models/subject_model.dart';
import '../models/subject_progress_model.dart';

class SubjectsRepository {
  final SubjectsRemoteDataSource _remoteDataSource;

  SubjectsRepository({SubjectsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? SubjectsRemoteDataSource();

  Future<List<SubjectModel>> getSubjects({bool includeArchived = false}) {
    return _remoteDataSource.getSubjects(includeArchived: includeArchived);
  }

  Future<SubjectModel> createSubject({
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) {
    return _remoteDataSource.createSubject(
      name: name,
      color: color,
      icon: icon,
      dailyTargetMinutes: dailyTargetMinutes,
    );
  }

  Future<SubjectModel> updateSubject({
    required String id,
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) {
    return _remoteDataSource.updateSubject(
      id: id,
      name: name,
      color: color,
      icon: icon,
      dailyTargetMinutes: dailyTargetMinutes,
    );
  }

  Future<SubjectModel> getSubjectById(String id) {
    return _remoteDataSource.getSubjectById(id);
  }

  Future<SubjectProgressModel> getSubjectProgress(String id) {
    return _remoteDataSource.getSubjectProgress(id);
  }

  Future<List<ChapterModel>> getSubjectChapters(String id) {
    return _remoteDataSource.getSubjectChapters(id);
  }

  Future<ChapterModel> createChapter({
    required String subjectId,
    required String title,
    int? order,
  }) {
    return _remoteDataSource.createChapter(
      subjectId: subjectId,
      title: title,
      order: order,
    );
  }

  Future<ChapterModel> updateChapter({
    required String subjectId,
    required String chapterId,
    String? title,
    int? order,
    bool? completed,
  }) {
    return _remoteDataSource.updateChapter(
      subjectId: subjectId,
      chapterId: chapterId,
      title: title,
      order: order,
      completed: completed,
    );
  }

  Future<void> deleteSubject(String id) {
    return _remoteDataSource.deleteSubject(id);
  }
}
