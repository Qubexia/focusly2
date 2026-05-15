import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';
import '../../../analytics/data/repositories/analytics_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    SubjectsRepository? repository,
    AnalyticsRepository? analyticsRepository,
  })  : _repository = repository ?? SubjectsRepository(),
        _analyticsRepository = analyticsRepository ?? AnalyticsRepository(),
        super(const HomeState());

  final SubjectsRepository _repository;
  final AnalyticsRepository _analyticsRepository;

  Future<void> loadHome() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final subjects = await _repository.getSubjects();
      var streak = 0;
      String? warningMessage;

      try {
        final summary = await _analyticsRepository.getSummary();
        streak = summary.streak;
      } on DioException catch (e) {
        warningMessage = _extractMessage(e);
      } catch (_) {
        warningMessage = 'Analytics is temporarily unavailable.';
      }

      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
          streak: streak,
          errorMessage: warningMessage,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load home data.',
        ),
      );
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}
