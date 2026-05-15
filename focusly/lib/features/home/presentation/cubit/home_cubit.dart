import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({SubjectsRepository? repository})
      : _repository = repository ?? SubjectsRepository(),
        super(const HomeState());

  final SubjectsRepository _repository;

  Future<void> loadHome() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final subjects = await _repository.getSubjects();
      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
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
