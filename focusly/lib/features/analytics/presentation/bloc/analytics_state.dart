import 'package:equatable/equatable.dart';
import '../../data/models/analytics_performance_model.dart';
import '../../data/models/analytics_summary_model.dart';
import '../../data/models/analytics_subject_model.dart';

enum AnalyticsDateRange { week, month, year, custom }

class AnalyticsState extends Equatable {
  const AnalyticsState({
    this.summary,
    this.bySubject = const [],
    this.performance,
    this.isLoading = false,
    this.errorMessage,
    this.dateRange = AnalyticsDateRange.week,
    this.fromDate,
    this.toDate,
  });

  final AnalyticsSummaryModel? summary;
  final List<AnalyticsSubjectModel> bySubject;
  final AnalyticsPerformanceModel? performance;
  final bool isLoading;
  final String? errorMessage;
  final AnalyticsDateRange dateRange;
  final DateTime? fromDate;
  final DateTime? toDate;

  AnalyticsState copyWith({
    AnalyticsSummaryModel? summary,
    List<AnalyticsSubjectModel>? bySubject,
    AnalyticsPerformanceModel? performance,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    AnalyticsDateRange? dateRange,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return AnalyticsState(
      summary: summary ?? this.summary,
      bySubject: bySubject ?? this.bySubject,
      performance: performance ?? this.performance,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      dateRange: dateRange ?? this.dateRange,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        bySubject,
        performance,
        isLoading,
        errorMessage,
        dateRange,
        fromDate,
        toDate,
      ];
}
