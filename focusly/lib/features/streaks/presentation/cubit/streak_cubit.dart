import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakerly/core/localization/app_l10n.dart';
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
          streak: streak,
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
          errorMessage: AppL10n.current.streaksLoadFailed,
        ),
      );
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }
}
