import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakerly/core/localization/app_l10n.dart';
import '../../../../core/services/premium_refresh_service.dart';
import '../../data/models/ai_artifact_model.dart';
import '../../data/repositories/ai_repository.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';

part 'ai_notes_state.dart';

class AiNotesCubit extends Cubit<AiNotesState> {
  AiNotesCubit({
    AiRepository? aiRepository,
    SubjectsRepository? subjectsRepository,
  })  : _aiRepository = aiRepository ?? AiRepository(),
        _subjectsRepository = subjectsRepository ?? SubjectsRepository(),
        super(const AiNotesState());

  final AiRepository _aiRepository;
  final SubjectsRepository _subjectsRepository;

  Future<void> loadHub() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await PremiumRefreshService.instance.refreshSessionTokens();
      final subjects = await _subjectsRepository.getSubjects();
      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
          selectedSubjectId:
              state.selectedSubjectId ?? (subjects.isNotEmpty ? subjects.first.id : null),
        ),
      );
      if (state.selectedSubjectId != null) {
        await loadArtifacts(state.selectedSubjectId!);
      }
    } catch (_) {
      emit(state.copyWith(
          isLoading: false,
          errorMessage: AppL10n.current.aiLoadSubjectsFailed));
    }
  }

  Future<void> selectSubject(String subjectId) async {
    emit(state.copyWith(selectedSubjectId: subjectId));
    await loadArtifacts(subjectId);
  }

  Future<List<AiArtifactModel>> loadArtifacts(String subjectId) async {
    emit(state.copyWith(isLoadingArtifacts: true));
    try {
      final artifacts = await _aiRepository.getArtifacts(subjectId: subjectId);
      emit(state.copyWith(isLoadingArtifacts: false, artifacts: artifacts));
      return artifacts;
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoadingArtifacts: false,
          errorMessage: _extractMessage(e),
        ),
      );
      return const [];
    }
  }

  Future<void> deleteJobPack(String jobId) async {
    if (state.deletingJobId != null) return;

    emit(state.copyWith(deletingJobId: jobId, clearError: true));
    try {
      await _aiRepository.deleteJobArtifacts(jobId);
      final updatedArtifacts =
          state.artifacts.where((artifact) => artifact.jobId != jobId).toList();
      emit(
        state.copyWith(
          deletingJobId: null,
          artifacts: updatedArtifacts,
          feedbackMessage: AppL10n.current.aiStudyPackDeleted,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          deletingJobId: null,
          errorMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          deletingJobId: null,
          errorMessage: AppL10n.current.aiDeleteStudyPackFailed,
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
      if (data['error'] == 'AI_RATE_LIMIT') {
        return AppL10n.current.aiRateLimitReached;
      }
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }
}
