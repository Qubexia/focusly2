import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/subject_model.dart';
import '../../data/repositories/subjects_repository.dart';

part 'subjects_state.dart';

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit({SubjectsRepository? repository})
    : _repository = repository ?? SubjectsRepository(),
      super(const SubjectsState());

  final SubjectsRepository _repository;

  Future<void> loadSubjects() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      final subjects = await _repository.getSubjects();
      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
          errorMessage: null,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _extractMessage(e),
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load subjects.',
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: e.toString(),
        ),
      );
    }
  }

  Future<bool> createSubject({
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) async {
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final created = await _repository.createSubject(
        name: name,
        color: color,
        icon: icon,
        dailyTargetMinutes: dailyTargetMinutes,
      );
      emit(
        state.copyWith(
          isSaving: false,
          subjects: [created, ...state.subjects],
          feedbackType: SubjectsFeedbackType.success,
          feedbackMessage: 'Subject created successfully.',
        ),
      );
      return true;
    } on DioException catch (e) {
      final code = _extractCode(e);
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: code == 'SUBJECT_LIMIT_REACHED'
              ? SubjectsFeedbackType.premiumGate
              : SubjectsFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: 'Failed to create subject.',
        ),
      );
      return false;
    }
  }

  Future<bool> updateSubject({
    required String id,
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) async {
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final updated = await _repository.updateSubject(
        id: id,
        name: name,
        color: color,
        icon: icon,
        dailyTargetMinutes: dailyTargetMinutes,
      );

      final nextSubjects = state.subjects
          .map((subject) => subject.id == id ? updated : subject)
          .toList();

      emit(
        state.copyWith(
          isSaving: false,
          subjects: nextSubjects,
          feedbackType: SubjectsFeedbackType.success,
          feedbackMessage: 'Subject updated successfully.',
        ),
      );
      return true;
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: 'Failed to update subject.',
        ),
      );
      return false;
    }
  }

  Future<void> deleteSubject(String id) async {
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      await _repository.deleteSubject(id);
      emit(
        state.copyWith(
          isSaving: false,
          subjects: state.subjects
              .where((subject) => subject.id != id)
              .toList(),
          feedbackType: SubjectsFeedbackType.success,
          feedbackMessage: 'Subject archived successfully.',
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectsFeedbackType.error,
          feedbackMessage: 'Failed to archive subject.',
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }

  String? _extractCode(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['code'] as String?;
    }
    return null;
  }
}
