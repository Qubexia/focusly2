import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/chapter_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/subject_progress_model.dart';
import '../../data/repositories/subjects_repository.dart';

part 'subject_detail_state.dart';

class SubjectDetailCubit extends Cubit<SubjectDetailState> {
  SubjectDetailCubit({SubjectsRepository? repository})
      : _repository = repository ?? SubjectsRepository(),
        super(const SubjectDetailState());

  final SubjectsRepository _repository;

  Future<void> load(String subjectId) async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      final results = await Future.wait<dynamic>([
        _repository.getSubjectById(subjectId),
        _repository.getSubjectProgress(subjectId),
        _repository.getSubjectChapters(subjectId),
      ]);

      emit(
        state.copyWith(
          isLoading: false,
          subject: results[0] as SubjectModel,
          progress: results[1] as SubjectProgressModel,
          chapters: results[2] as List<ChapterModel>,
          errorMessage: null,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _extractMessage(e),
          feedbackMessage: _extractMessage(e),
          feedbackType: SubjectDetailFeedbackType.error,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load subject details.',
          feedbackMessage: 'Failed to load subject details.',
          feedbackType: SubjectDetailFeedbackType.error,
        ),
      );
    }
  }

  Future<bool> createChapter(String title) async {
    final subject = state.subject;
    if (subject == null) return false;

    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      await _repository.createChapter(
        subjectId: subject.id,
        title: title,
        order: state.chapters.length + 1,
      );
      await load(subject.id);
      emit(
        state.copyWith(
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: 'Chapter added successfully.',
        ),
      );
      return true;
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: 'Failed to add chapter.',
        ),
      );
      return false;
    }
  }

  Future<bool> renameChapter({
    required String chapterId,
    required String title,
  }) async {
    final subject = state.subject;
    if (subject == null) return false;

    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      await _repository.updateChapter(
        subjectId: subject.id,
        chapterId: chapterId,
        title: title,
      );
      await load(subject.id);
      emit(
        state.copyWith(
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: 'Chapter updated successfully.',
        ),
      );
      return true;
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: 'Failed to update chapter.',
        ),
      );
      return false;
    }
  }

  Future<void> toggleChapter(ChapterModel chapter, bool completed) async {
    final subject = state.subject;
    if (subject == null) return;

    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final updated = await _repository.updateChapter(
        subjectId: subject.id,
        chapterId: chapter.id,
        completed: completed,
      );

      final chapters = state.chapters
          .map((item) => item.id == chapter.id ? updated : item)
          .toList();

      final completedCount = chapters.where((item) => item.completed).length;
      final progressPercent = chapters.isEmpty
          ? 0
          : ((completedCount / chapters.length) * 100).round();

      emit(
        state.copyWith(
          isSaving: false,
          chapters: chapters,
          progress: SubjectProgressModel(
            progressPercent: progressPercent,
            chaptersTotal: chapters.length,
            chaptersCompleted: completedCount,
          ),
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: 'Failed to update chapter.',
        ),
      );
    }
  }

  Future<bool> updateSubject({
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
  }) async {
    final subject = state.subject;
    if (subject == null) return false;

    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final updated = await _repository.updateSubject(
        id: subject.id,
        name: name,
        color: color,
        icon: icon,
        dailyTargetMinutes: dailyTargetMinutes,
      );

      emit(
        state.copyWith(
          isSaving: false,
          subject: updated,
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: 'Subject updated successfully.',
        ),
      );
      return true;
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: 'Failed to update subject.',
        ),
      );
      return false;
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
}
