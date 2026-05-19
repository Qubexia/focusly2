import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/streaks_repository.dart';
import 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  StreakCubit({StreaksRepository? repository})
      : _repository = repository ?? StreaksRepository(),
        super(const StreakState());

  final StreaksRepository _repository;

  Future<void> loadStreak() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final streak = await _repository.getMyStreak();
      emit(
        state.copyWith(
          isLoading: false,
          current: streak.current,
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
          errorMessage: 'Failed to load streak.',
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
