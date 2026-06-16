part of 'ai_notes_cubit.dart';

class AiNotesState extends Equatable {
  const AiNotesState({
    this.subjects = const [],
    this.artifacts = const [],
    this.selectedSubjectId,
    this.deletingJobId,
    this.isLoading = false,
    this.isLoadingArtifacts = false,
    this.errorMessage,
    this.feedbackMessage,
  });

  final List<SubjectModel> subjects;
  final List<AiArtifactModel> artifacts;
  final String? selectedSubjectId;
  final String? deletingJobId;
  final bool isLoading;
  final bool isLoadingArtifacts;
  final String? errorMessage;
  final String? feedbackMessage;

  AiNotesState copyWith({
    List<SubjectModel>? subjects,
    List<AiArtifactModel>? artifacts,
    String? selectedSubjectId,
    String? deletingJobId,
    bool? isLoading,
    bool? isLoadingArtifacts,
    String? errorMessage,
    String? feedbackMessage,
    bool clearError = false,
    bool clearFeedback = false,
  }) {
    return AiNotesState(
      subjects: subjects ?? this.subjects,
      artifacts: artifacts ?? this.artifacts,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      deletingJobId: deletingJobId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingArtifacts: isLoadingArtifacts ?? this.isLoadingArtifacts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        subjects,
        artifacts,
        selectedSubjectId,
        deletingJobId,
        isLoading,
        isLoadingArtifacts,
        errorMessage,
        feedbackMessage,
      ];
}
