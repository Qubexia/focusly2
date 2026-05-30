part of 'ai_notes_cubit.dart';

class AiNotesState extends Equatable {
  const AiNotesState({
    this.subjects = const [],
    this.artifacts = const [],
    this.pickedImagePaths = const [],
    this.selectedSubjectId,
    this.activeJobId,
    this.isLoading = false,
    this.isLoadingArtifacts = false,
    this.isSubmitting = false,
    this.jobProgress = 0,
    this.errorMessage,
    this.feedbackMessage,
    this.viewerArtifacts,
  });

  final List<SubjectModel> subjects;
  final List<AiArtifactModel> artifacts;
  final List<String> pickedImagePaths;
  final String? selectedSubjectId;
  final String? activeJobId;
  final bool isLoading;
  final bool isLoadingArtifacts;
  final bool isSubmitting;
  final double jobProgress;
  final String? errorMessage;
  final String? feedbackMessage;
  final List<AiArtifactModel>? viewerArtifacts;

  AiNotesState copyWith({
    List<SubjectModel>? subjects,
    List<AiArtifactModel>? artifacts,
    List<String>? pickedImagePaths,
    String? selectedSubjectId,
    String? activeJobId,
    bool? isLoading,
    bool? isLoadingArtifacts,
    bool? isSubmitting,
    double? jobProgress,
    String? errorMessage,
    String? feedbackMessage,
    List<AiArtifactModel>? viewerArtifacts,
    bool clearError = false,
    bool clearFeedback = false,
    bool clearViewer = false,
  }) {
    return AiNotesState(
      subjects: subjects ?? this.subjects,
      artifacts: artifacts ?? this.artifacts,
      pickedImagePaths: pickedImagePaths ?? this.pickedImagePaths,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      activeJobId: activeJobId ?? this.activeJobId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingArtifacts: isLoadingArtifacts ?? this.isLoadingArtifacts,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      jobProgress: jobProgress ?? this.jobProgress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      viewerArtifacts:
          clearViewer ? null : (viewerArtifacts ?? this.viewerArtifacts),
    );
  }

  @override
  List<Object?> get props => [
        subjects,
        artifacts,
        pickedImagePaths,
        selectedSubjectId,
        activeJobId,
        isLoading,
        isLoadingArtifacts,
        isSubmitting,
        jobProgress,
        errorMessage,
        feedbackMessage,
        viewerArtifacts,
      ];
}
