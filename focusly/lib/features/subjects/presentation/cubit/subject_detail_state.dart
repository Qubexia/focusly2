part of 'subject_detail_cubit.dart';

enum SubjectDetailFeedbackType { none, success, error }

class SubjectDetailState extends Equatable {
  const SubjectDetailState({
    this.subject,
    this.progress,
    this.chapters = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.feedbackType = SubjectDetailFeedbackType.none,
    this.feedbackMessage,
    this.analyzingChapterIds = const {},
    this.isAnalyzingSubject = false,
  });

  final SubjectModel? subject;
  final SubjectProgressModel? progress;
  final List<ChapterModel> chapters;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final SubjectDetailFeedbackType feedbackType;
  final String? feedbackMessage;

  /// Chapter ids whose uploaded PDF is currently being analyzed by the AI.
  final Set<String> analyzingChapterIds;

  /// Whether a subject-level PDF is currently being analyzed.
  final bool isAnalyzingSubject;

  SubjectDetailState copyWith({
    SubjectModel? subject,
    SubjectProgressModel? progress,
    List<ChapterModel>? chapters,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    SubjectDetailFeedbackType? feedbackType,
    String? feedbackMessage,
    Set<String>? analyzingChapterIds,
    bool? isAnalyzingSubject,
    bool clearFeedback = false,
  }) {
    return SubjectDetailState(
      subject: subject ?? this.subject,
      progress: progress ?? this.progress,
      chapters: chapters ?? this.chapters,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      feedbackType: clearFeedback
          ? SubjectDetailFeedbackType.none
          : feedbackType ?? this.feedbackType,
      feedbackMessage: clearFeedback ? null : feedbackMessage,
      analyzingChapterIds: analyzingChapterIds ?? this.analyzingChapterIds,
      isAnalyzingSubject: isAnalyzingSubject ?? this.isAnalyzingSubject,
    );
  }

  @override
  List<Object?> get props => [
        subject,
        progress,
        chapters,
        isLoading,
        isSaving,
        errorMessage,
        feedbackType,
        feedbackMessage,
        analyzingChapterIds,
        isAnalyzingSubject,
      ];
}
