import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zakerly/core/localization/app_l10n.dart';
import '../../../../core/services/upload_service.dart';
import '../../../ai/data/models/ai_artifact_model.dart';
import '../../../ai/data/repositories/ai_repository.dart';
import '../../data/models/chapter_model.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/subject_progress_model.dart';
import '../../data/repositories/subjects_repository.dart';

part 'subject_detail_state.dart';

class SubjectDetailCubit extends Cubit<SubjectDetailState> {
  SubjectDetailCubit({
    SubjectsRepository? repository,
    AiRepository? aiRepository,
    UploadService? uploadService,
  })  : _repository = repository ?? SubjectsRepository(),
        _aiRepository = aiRepository ?? AiRepository(),
        _uploadService = uploadService ?? UploadService(),
        super(const SubjectDetailState());

  final SubjectsRepository _repository;
  final AiRepository _aiRepository;
  final UploadService _uploadService;

  Future<void> load(String subjectId) async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    try {
      final subject = await _repository.getSubjectById(subjectId);
      final progress = await _repository.getSubjectProgress(subjectId);
      final chapters = await _repository.getSubjectChapters(subjectId);

      emit(
        state.copyWith(
          isLoading: false,
          subject: subject,
          progress: progress,
          chapters: chapters,
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
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: '${AppL10n.current.subjectsDetailLoadFailed}: $e',
          feedbackMessage: '${AppL10n.current.subjectsDetailLoadFailed}: $e',
          feedbackType: SubjectDetailFeedbackType.error,
        ),
      );
    }
  }

  Future<bool> createChapter(
    String title, {
    String? pdfPath,
    String language = 'auto',
    String detailLevel = 'medium',
  }) async {
    final subject = state.subject;
    if (subject == null) return false;

    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final chapter = await _repository.createChapter(
        subjectId: subject.id,
        title: title,
        order: state.chapters.length + 1,
      );

      final chapters = [...state.chapters, chapter]..sort(
        (first, second) => first.order.compareTo(second.order),
      );

      emit(
        state.copyWith(
          isSaving: false,
          chapters: chapters,
          progress: _buildProgress(chapters),
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: pdfPath != null
              ? AppL10n.current.subjectsChapterAddedAnalyzing
              : AppL10n.current.subjectsChapterAddedSuccess,
        ),
      );

      await _refreshSubjectDetails(subject.id);

      if (pdfPath != null) {
        // Fire-and-forget: analysis runs in the background and updates state.
        unawaited(
          analyzeChapterPdf(
            chapterId: chapter.id,
            pdfPath: pdfPath,
            language: language,
            detailLevel: detailLevel,
          ),
        );
      }

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
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: '${AppL10n.current.subjectsChapterAddFailed}: $e',
        ),
      );
      return false;
    }
  }

  /// Uploads a PDF for a chapter and submits an AI job that generates study
  /// materials (summary / flashcards / questions) scoped to that chapter.
  Future<void> analyzeChapterPdf({
    required String chapterId,
    required String pdfPath,
    String language = 'auto',
    String detailLevel = 'medium',
  }) async {
    final subject = state.subject;
    if (subject == null) return;

    emit(
      state.copyWith(
        analyzingChapterIds: {...state.analyzingChapterIds, chapterId},
      ),
    );

    try {
      final fileId = await _uploadService.uploadAiFile(
        file: File(pdfPath),
        mimeType: 'application/pdf',
      );

      final jobId = await _aiRepository.submitJob(
        pdfKeys: [fileId],
        subjectId: subject.id,
        chapterId: chapterId,
        language: language,
        detailLevel: detailLevel,
      );

      await _waitForJob(jobId);

      emit(
        state.copyWith(
          analyzingChapterIds: _withoutChapter(chapterId),
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: AppL10n.current.subjectsChapterMaterialsReady,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          analyzingChapterIds: _withoutChapter(chapterId),
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          analyzingChapterIds: _withoutChapter(chapterId),
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _formatAnalysisError(e),
        ),
      );
    }
  }

  /// Uploads a PDF for the whole subject and submits an AI job scoped to it.
  Future<void> analyzeSubjectPdf({
    required String pdfPath,
    String language = 'auto',
    String detailLevel = 'medium',
  }) async {
    final subject = state.subject;
    if (subject == null) return;

    emit(state.copyWith(isAnalyzingSubject: true, clearFeedback: true));

    try {
      final fileId = await _uploadService.uploadAiFile(
        file: File(pdfPath),
        mimeType: 'application/pdf',
      );

      final jobId = await _aiRepository.submitJob(
        pdfKeys: [fileId],
        subjectId: subject.id,
        language: language,
        detailLevel: detailLevel,
      );

      await _waitForJob(jobId);

      emit(
        state.copyWith(
          isAnalyzingSubject: false,
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: AppL10n.current.subjectsMaterialsReady,
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isAnalyzingSubject: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _extractMessage(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isAnalyzingSubject: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: _formatAnalysisError(e),
        ),
      );
    }
  }

  /// Fetches the AI study materials generated for a single chapter.
  Future<List<AiArtifactModel>> loadChapterArtifacts(String chapterId) {
    return _aiRepository.getArtifacts(chapterId: chapterId);
  }

  /// Fetches the AI study materials generated at the subject level.
  Future<List<AiArtifactModel>> loadSubjectArtifacts() {
    final subject = state.subject;
    if (subject == null) return Future.value(const []);
    return _aiRepository.getArtifacts(subjectId: subject.id);
  }

  Set<String> _withoutChapter(String chapterId) {
    return state.analyzingChapterIds.where((id) => id != chapterId).toSet();
  }

  /// Polls a job until it reaches a terminal state. Throws on failure.
  Future<void> _waitForJob(String jobId) async {
    const maxAttempts = 90; // ~3 minutes at 2s intervals
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final job = await _aiRepository.getJob(jobId);
      if (job.isCompleted) return;
      if (job.isFailed) {
        throw Exception(job.failureReason ?? AppL10n.current.subjectsAiJobFailed);
      }
    }
    throw Exception(AppL10n.current.subjectsAiAnalysisTimedOut);
  }

  Future<bool> renameChapter({
    required String chapterId,
    required String title,
  }) async {
    final subject = state.subject;
    if (subject == null) return false;

    emit(state.copyWith(isSaving: true, clearFeedback: true));
    try {
      final updated = await _repository.updateChapter(
        subjectId: subject.id,
        chapterId: chapterId,
        title: title,
      );

      final chapters = state.chapters
          .map((chapter) => chapter.id == chapterId ? updated : chapter)
          .toList()
        ..sort((first, second) => first.order.compareTo(second.order));

      emit(
        state.copyWith(
          isSaving: false,
          chapters: chapters,
          progress: _buildProgress(chapters),
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: AppL10n.current.subjectsChapterUpdateSuccess,
        ),
      );

      await _refreshSubjectDetails(subject.id);

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
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          feedbackType: SubjectDetailFeedbackType.error,
          feedbackMessage: '${AppL10n.current.subjectsChapterUpdateFailed}: $e',
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
          feedbackMessage: AppL10n.current.subjectsChapterUpdateFailedShort,
        ),
      );
    }
  }

  Future<bool> updateSubject({
    required String name,
    String? color,
    String? icon,
    required int dailyTargetMinutes,
    String? goalType,
    List<int>? goalDays,
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
        goalType: goalType,
        goalDays: goalDays,
      );

      emit(
        state.copyWith(
          isSaving: false,
          subject: updated,
          feedbackType: SubjectDetailFeedbackType.success,
          feedbackMessage: AppL10n.current.subjectsUpdateSuccess,
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
          feedbackMessage: AppL10n.current.subjectsUpdateFailed,
        ),
      );
      return false;
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  Future<void> _refreshSubjectDetails(String subjectId) async {
    try {
      final results = await Future.wait<dynamic>([
        _repository.getSubjectById(subjectId),
        _repository.getSubjectProgress(subjectId),
        _repository.getSubjectChapters(subjectId),
      ]);

      emit(
        state.copyWith(
          isSaving: false,
          subject: results[0] as SubjectModel,
          progress: results[1] as SubjectProgressModel,
          chapters: results[2] as List<ChapterModel>,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isSaving: false));
    }
  }

  SubjectProgressModel _buildProgress(List<ChapterModel> chapters) {
    final completedCount = chapters.where((item) => item.completed).length;
    final progressPercent = chapters.isEmpty
        ? 0
        : ((completedCount / chapters.length) * 100).round();

    return SubjectProgressModel(
      progressPercent: progressPercent,
      chaptersTotal: chapters.length,
      chaptersCompleted: completedCount,
    );
  }

  String _formatAnalysisError(Object error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.startsWith('Exception: ')) {
        return message.substring('Exception: '.length);
      }
      return message;
    }
    return AppL10n.current.subjectsAnalyzePdfFailed;
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List && message.isNotEmpty) return message.first.toString();
      return AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }
}
