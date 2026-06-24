import '../datasources/pomodoro_remote_datasource.dart';
import '../models/pomodoro_session_model.dart';
import '../models/pomodoro_today_model.dart';

class PomodoroRepository {
  PomodoroRepository({PomodoroRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? PomodoroRemoteDataSource();

  final PomodoroRemoteDataSource _remoteDataSource;

  Future<PomodoroSessionModel> startSession({
    String? subjectId,
    required int focusMinutes,
    required int breakMinutes,
    required int sessionMinutes,
    String breakMode = 'cycles',
  }) {
    return _remoteDataSource.startSession(
      subjectId: subjectId,
      focusMinutes: focusMinutes,
      breakMinutes: breakMinutes,
      sessionMinutes: sessionMinutes,
      breakMode: breakMode,
    );
  }

  Future<PomodoroSessionModel> pauseSession(String id) {
    return _remoteDataSource.pauseSession(id);
  }

  Future<PomodoroSessionModel> resumeSession(String id) {
    return _remoteDataSource.resumeSession(id);
  }

  Future<PomodoroSessionModel> completeSession(String id) {
    return _remoteDataSource.completeSession(id);
  }

  Future<PomodoroSessionModel> abortSession(String id) {
    return _remoteDataSource.abortSession(id);
  }

  Future<PomodoroTodayModel> getToday() {
    return _remoteDataSource.getToday();
  }

  Future<List<PomodoroSessionModel>> getHistory({
    required String from,
    required String to,
    int limit = 50,
    String? cursor,
  }) {
    return _remoteDataSource.getHistory(
      from: from,
      to: to,
      limit: limit,
      cursor: cursor,
    );
  }
}
