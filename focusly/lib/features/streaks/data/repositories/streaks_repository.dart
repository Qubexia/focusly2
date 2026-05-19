import '../datasources/streaks_remote_datasource.dart';
import '../models/streak_model.dart';

class StreaksRepository {
  StreaksRepository({StreaksRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? StreaksRemoteDataSource();

  final StreaksRemoteDataSource _remoteDataSource;

  Future<StreakModel> getMyStreak() {
    return _remoteDataSource.getMyStreak();
  }
}
