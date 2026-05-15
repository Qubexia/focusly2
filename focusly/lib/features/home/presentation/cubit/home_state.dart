part of 'home_cubit.dart';

class HomeState extends Equatable {
  const HomeState({
    this.subjects = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SubjectModel> subjects;
  final bool isLoading;
  final String? errorMessage;

  HomeState copyWith({
    List<SubjectModel>? subjects,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      subjects: subjects ?? this.subjects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
    );
  }

  @override
  List<Object?> get props => [subjects, isLoading, errorMessage];
}
