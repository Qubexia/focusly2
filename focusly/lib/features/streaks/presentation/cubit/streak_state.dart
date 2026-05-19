import 'package:equatable/equatable.dart';

class StreakState extends Equatable {
  const StreakState({
    this.current = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final int current;
  final bool isLoading;
  final String? errorMessage;

  StreakState copyWith({
    int? current,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StreakState(
      current: current ?? this.current,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [current, isLoading, errorMessage];
}
