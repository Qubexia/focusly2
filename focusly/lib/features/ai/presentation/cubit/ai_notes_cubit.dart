import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/upload_service.dart';
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
    UploadService? uploadService,
  })  : _aiRepository = aiRepository ?? AiRepository(),
        _subjectsRepository = subjectsRepository ?? SubjectsRepository(),
        _uploadService = uploadService ?? UploadService(),
        super(const AiNotesState());

  final AiRepository _aiRepository;
  final SubjectsRepository _subjectsRepository;
  final UploadService _uploadService;
  final ImagePicker _picker = ImagePicker();
  Timer? _pollTimer;

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
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load subjects.'));
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

  Future<void> pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    _appendPaths(files.map((f) => f.path));
  }

  Future<void> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return;
    _appendPaths([file.path]);
  }

  void _appendPaths(Iterable<String> paths) {
    final list = paths.where((p) => p.isNotEmpty).toList();
    if (list.isEmpty) return;
    emit(
      state.copyWith(
        pickedImagePaths: [...state.pickedImagePaths, ...list],
      ),
    );
  }

  void removeImageAt(int index) {
    final paths = [...state.pickedImagePaths]..removeAt(index);
    emit(state.copyWith(pickedImagePaths: paths));
  }

  Future<void> submitJob() async {
    if (state.selectedSubjectId == null) {
      emit(state.copyWith(errorMessage: 'Select a subject first.'));
      return;
    }
    if (state.pickedImagePaths.isEmpty) {
      emit(state.copyWith(errorMessage: 'Add at least one image.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, jobProgress: 0));
    try {
      final keys = <String>[];
      for (var i = 0; i < state.pickedImagePaths.length; i++) {
        final key = await _uploadService.uploadFile(
          file: File(state.pickedImagePaths[i]),
          kind: 'ai-notes-image',
        );
        keys.add(key);
        emit(state.copyWith(jobProgress: ((i + 1) / state.pickedImagePaths.length) * 0.5));
      }

      final jobId = await _submitJobWithPremiumRetry(
        imageKeys: keys,
        subjectId: state.selectedSubjectId,
      );

      emit(
        state.copyWith(
          activeJobId: jobId,
          jobProgress: 0.55,
          pickedImagePaths: const [],
        ),
      );
      _startPolling(jobId);
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to submit AI job.',
        ),
      );
    }
  }

  Future<String> _submitJobWithPremiumRetry({
    required List<String> imageKeys,
    required String? subjectId,
  }) async {
    try {
      return await _aiRepository.submitJob(
        imageKeys: imageKeys,
        subjectId: subjectId,
      );
    } on DioException catch (e) {
      if (isPremiumRequiredError(e.response?.data) &&
          await PremiumRefreshService.instance.refreshSessionTokens()) {
        return _aiRepository.submitJob(
          imageKeys: imageKeys,
          subjectId: subjectId,
        );
      }
      rethrow;
    }
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final job = await _aiRepository.getJob(jobId);
        if (job.isCompleted) {
          _pollTimer?.cancel();
          final subjectId = state.selectedSubjectId;
          var jobArtifacts = <AiArtifactModel>[];
          if (subjectId != null) {
            final artifacts = await loadArtifacts(subjectId);
            jobArtifacts =
                artifacts.where((a) => a.jobId == jobId).toList();
          }
          emit(
            state.copyWith(
              isSubmitting: false,
              jobProgress: 1,
              activeJobId: null,
              feedbackMessage: 'Notes generated successfully!',
              viewerArtifacts: jobArtifacts.isNotEmpty ? jobArtifacts : null,
            ),
          );
        } else if (job.isFailed) {
          _pollTimer?.cancel();
          emit(
            state.copyWith(
              isSubmitting: false,
              activeJobId: null,
              errorMessage: job.failureReason ?? 'AI job failed.',
            ),
          );
        } else {
          emit(state.copyWith(jobProgress: 0.75));
        }
      } catch (_) {}
    });
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  void clearViewerNavigation() {
    emit(state.copyWith(clearViewer: true));
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['error'] == 'AI_RATE_LIMIT') {
        return 'AI rate limit reached. Try again later.';
      }
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
