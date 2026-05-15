import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    DateTime? finalFrom = from ?? state.fromDate;
    DateTime? finalTo = to ?? state.toDate;

    if (range != null && range != AnalyticsDateRange.custom) {
      final now = DateTime.now();
      finalTo = now;
      if (range == AnalyticsDateRange.week) {
        finalFrom = _startOfCurrentWeek(now);
      } else if (range == AnalyticsDateRange.month) {
        finalFrom = DateTime(now.year, now.month, 1);
      } else if (range == AnalyticsDateRange.year) {
        finalFrom = DateTime(now.year, 1, 1);
      }
    }

    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      dateRange: newRange,
      fromDate: finalFrom,
      toDate: finalTo,
    ));

    final fromStr = finalFrom != null ? _formatDate(finalFrom) : null;
    final toStr = finalTo != null ? _formatDate(finalTo) : null;

    try {
      final results = await Future.wait([
        _repository.getSummary(from: fromStr, to: toStr),
        _repository.getBySubject(from: fromStr, to: toStr),
      ]);

      emit(state.copyWith(
        isLoading: false,
        summary: results[0] as dynamic,
        bySubject: results[1] as dynamic,
      ));
    } on DioException catch (e) {
      final message = _extractMessage(e);
      final isPremiumError = message.toLowerCase().contains('premium');
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
        errorMessage: 'Failed to load analytics data.',
      ));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _startOfCurrentWeek(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final daysSinceSunday = date.weekday % 7;
    return startOfDay.subtract(Duration(days: daysSinceSunday));
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }

  Future<void> _loadWeeklyFallback(String upgradeMessage) async {
    final now = DateTime.now();
    final fromDate = _startOfCurrentWeek(now);
    final toDate = now;
    final fromStr = _formatDate(fromDate);
    final toStr = _formatDate(toDate);

    try {
      final results = await Future.wait([
        _repository.getSummary(from: fromStr, to: toStr),
        _repository.getBySubject(from: fromStr, to: toStr),
      ]);

      emit(state.copyWith(
        isLoading: false,
        dateRange: AnalyticsDateRange.week,
        fromDate: fromDate,
        toDate: toDate,
        summary: results[0] as dynamic,
        bySubject: results[1] as dynamic,
        errorMessage: upgradeMessage,
      ));
    } on DioException catch (fallbackError) {
      final fallbackMessage = _extractMessage(fallbackError);
      final isPremiumError = fallbackMessage.toLowerCase().contains('premium');
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
