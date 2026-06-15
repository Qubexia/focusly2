import '../datasources/analytics_remote_datasource.dart';
import '../models/analytics_performance_model.dart';
import '../models/analytics_summary_model.dart';
import '../models/analytics_subject_model.dart';

class AnalyticsRepository {
  final AnalyticsRemoteDataSource _remoteDataSource;

  AnalyticsRepository({AnalyticsRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AnalyticsRemoteDataSource();

  Future<AnalyticsSummaryModel> getSummary({String? from, String? to}) {
    return _remoteDataSource.getSummary(from: from, to: to);
  }

  Future<List<AnalyticsSubjectModel>> getBySubject({String? from, String? to}) {
    return _remoteDataSource.getBySubject(from: from, to: to);
  }

  Future<AnalyticsPerformanceModel> getPerformance({
    String? from,
    String? to,
  }) {
    return _remoteDataSource.getPerformance(from: from, to: to);
  }
}
