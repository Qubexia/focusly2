import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zakerly/core/localization/app_l10n.dart';
import '../../data/models/analytics_performance_model.dart';
import '../../data/models/analytics_summary_model.dart';
import '../../data/repositories/analytics_repository.dart';
import 'analytics_state.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository(),
        super(const AnalyticsState());

  final AnalyticsRepository _repository;

  Future<void> loadAnalytics({
    AnalyticsDateRange? range,
    DateTime? from,
    DateTime? to,
  }) async {
    final newRange = range ?? state.dateRange;
    final resolvedRange = _resolveDateRange(
      range: newRange,
      from: from ?? state.fromDate,
      to: to ?? state.toDate,
    );
    final finalFrom = resolvedRange.$1;
    final finalTo = resolvedRange.$2;

    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      dateRange: newRange,
      fromDate: finalFrom,
      toDate: finalTo,
    ));

    final fromStr = _formatDate(finalFrom);
    final toStr = _formatDate(finalTo);

    try {
      final results = await Future.wait([
        _repository.getSummary(from: fromStr, to: toStr),
        _repository.getBySubject(from: fromStr, to: toStr),
        _repository.getPerformance(from: fromStr, to: toStr),
      ]);

      final summary = results[0] as AnalyticsSummaryModel;
      final performance =
          (results[2] as AnalyticsPerformanceModel).mergeWithSummary(
        focusMinutes: summary.totalFocusMinutes,
        sessions: summary.totalSessions,
        tasksCompleted: summary.totalTasksCompleted,
        streakDays: summary.streak,
      );

      emit(state.copyWith(
        isLoading: false,
        summary: summary,
        bySubject: results[1] as dynamic,
        performance: performance,
      ));
    } on DioException catch (e) {
      final message = _extractMessage(e);
      final isPremiumError = _isPremiumError(e);
      if (isPremiumError && newRange != AnalyticsDateRange.week) {
        await _loadWeeklyFallback(message);
        return;
      }
      if (isPremiumError) {
        emit(state.copyWith(
          isLoading: false,
          dateRange: AnalyticsDateRange.week,
          summary: _emptySummary(),
          bySubject: const [],
          errorMessage: message,
        ));
        return;
      }

      emit(state.copyWith(
        isLoading: false,
        errorMessage: message,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: AppL10n.current.analyticsLoadFailed,
      ));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  (DateTime, DateTime) _resolveDateRange({
    required AnalyticsDateRange range,
    DateTime? from,
    DateTime? to,
  }) {
    if (range == AnalyticsDateRange.custom && from != null && to != null) {
      return (from, to);
    }

    final nowUtc = DateTime.now().toUtc();
    final end = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);

    switch (range) {
      case AnalyticsDateRange.week:
        return (_startOfCurrentWeekUtc(end), end);
      case AnalyticsDateRange.month:
        return (DateTime.utc(end.year, end.month, 1), end);
      case AnalyticsDateRange.year:
        return (DateTime.utc(end.year, 1, 1), end);
      case AnalyticsDateRange.custom:
        return (from ?? _startOfCurrentWeekUtc(end), to ?? end);
    }
  }

  DateTime _startOfCurrentWeekUtc(DateTime date) {
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final daysSinceSunday = startOfDay.weekday % 7;
    return startOfDay.subtract(Duration(days: daysSinceSunday));
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }

  bool _isPremiumError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'] as String?;
      if (code == 'PREMIUM_REQUIRED') {
        return true;
      }

      final message = data['message'] as String?;
      if (message != null && message.toLowerCase().contains('premium')) {
        return true;
      }
    }

    return false;
  }

  Future<void> _loadWeeklyFallback(String upgradeMessage) async {
    final resolvedRange = _resolveDateRange(range: AnalyticsDateRange.week);
    final fromDate = resolvedRange.$1;
    final toDate = resolvedRange.$2;
    final fromStr = _formatDate(fromDate);
    final toStr = _formatDate(toDate);

    try {
      final results = await Future.wait([
        _repository.getSummary(from: fromStr, to: toStr),
        _repository.getBySubject(from: fromStr, to: toStr),
        _repository.getPerformance(from: fromStr, to: toStr),
      ]);

      final summary = results[0] as AnalyticsSummaryModel;
      final performance =
          (results[2] as AnalyticsPerformanceModel).mergeWithSummary(
        focusMinutes: summary.totalFocusMinutes,
        sessions: summary.totalSessions,
        tasksCompleted: summary.totalTasksCompleted,
        streakDays: summary.streak,
      );

      emit(state.copyWith(
        isLoading: false,
        dateRange: AnalyticsDateRange.week,
        fromDate: fromDate,
        toDate: toDate,
        summary: summary,
        bySubject: results[1] as dynamic,
        performance: performance,
        errorMessage: upgradeMessage,
      ));
    } on DioException catch (fallbackError) {
      final fallbackMessage = _extractMessage(fallbackError);
      final isPremiumError = _isPremiumError(fallbackError);
      if (isPremiumError) {
        emit(state.copyWith(
          isLoading: false,
          dateRange: AnalyticsDateRange.week,
          fromDate: fromDate,
          toDate: toDate,
          summary: _emptySummary(),
          bySubject: const [],
          errorMessage: upgradeMessage,
        ));
        return;
      }
      emit(state.copyWith(
        isLoading: false,
        errorMessage: fallbackMessage,
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        dateRange: AnalyticsDateRange.week,
        fromDate: fromDate,
        toDate: toDate,
        summary: _emptySummary(),
        bySubject: const [],
        errorMessage: upgradeMessage,
      ));
    }
  }

  AnalyticsSummaryModel _emptySummary() {
    return const AnalyticsSummaryModel(
      totalFocusMinutes: 0,
      totalSessions: 0,
      totalTasksCompleted: 0,
      streak: 0,
      dailyFocus: [],
    );
  }
}
