import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/planned_item_model.dart';
import '../../data/repositories/planner_repository.dart';

part 'planner_state.dart';

class PlannerCubit extends Cubit<PlannerState> {
  PlannerCubit({PlannerRepository? repository})
      : _repository = repository ?? PlannerRepository(),
        super(PlannerState(selectedDate: DateTime.now()));

  final PlannerRepository _repository;

  Future<void> loadDate(DateTime date) async {
    emit(state.copyWith(selectedDate: date, isLoading: true, clearError: true));
    
    final dateStr = _formatDate(date);

    try {
      // Fetch all 4 categories in parallel
      final results = await Future.wait([
        _repository.getItems(type: PlannedItemType.task, from: dateStr, to: dateStr),
        _repository.getItems(type: PlannedItemType.revision, from: dateStr, to: dateStr),
        _repository.getItems(type: PlannedItemType.lecture, from: dateStr, to: dateStr),
        _repository.getItems(type: PlannedItemType.exam, from: dateStr, to: dateStr),
      ]);

      emit(state.copyWith(
        isLoading: false,
        tasks: results[0],
        revisions: results[1],
        lectures: results[2],
        exams: results[3],
      ));
    } on DioException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: _extractMessage(e),
      ));
    } catch (_) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load items for this date.',
      ));
    }
  }

  Future<void> createItem({
    required PlannedItemType type,
    required String title,
    String? notes,
    required DateTime date,
    String? time,
    String? subjectId,
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _repository.createItem(
        type: type,
        title: title,
        notes: notes,
        plannedAt: _toPlannedAtIso(date, time),
        subjectId: subjectId,
      );

      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: 'Item created successfully!',
      ));
      
      // Refresh list for the selected date
      await loadDate(state.selectedDate);
    } on DioException catch (e) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: _extractMessage(e),
      ));
    } catch (_) {
      emit(state.copyWith(
        isSaving: false,
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: 'Failed to create item.',
      ));
    }
  }

  Future<void> completeItem(PlannedItemType type, String id) async {
    try {
      await _repository.completeItem(type: type, id: id);
      // Refresh the date to get updated statuses and potentially points (though UI updates optimistically if we want)
      await loadDate(state.selectedDate);
      
      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: 'Item completed! +Points earned',
      ));
    } catch (e) {
      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: 'Failed to complete item.',
      ));
    }
  }

  Future<void> deleteItem(PlannedItemType type, String id) async {
    try {
      await _repository.deleteItem(type: type, id: id);
      await loadDate(state.selectedDate);
      
      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.success,
        feedbackMessage: 'Item deleted successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(
        feedbackType: PlannerFeedbackType.error,
        feedbackMessage: 'Failed to delete item.',
      ));
    }
  }

  void clearFeedback() {
    emit(state.copyWith(clearFeedback: true));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _toPlannedAtIso(DateTime date, String? time) {
    final parsedTime = _parseTime(time);
    final plannedAt = DateTime(
      date.year,
      date.month,
      date.day,
      parsedTime?.$1 ?? 0,
      parsedTime?.$2 ?? 0,
    );
    return plannedAt.toIso8601String();
  }

  (int, int)? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final normalized = value.trim().toUpperCase();
    final isPm = normalized.endsWith('PM');
    final isAm = normalized.endsWith('AM');
    final timePart = normalized
        .replaceAll('AM', '')
        .replaceAll('PM', '')
        .trim();
    final pieces = timePart.split(':');
    if (pieces.length != 2) return null;

    final rawHour = int.tryParse(pieces[0]);
    final rawMinute = int.tryParse(pieces[1]);
    if (rawHour == null || rawMinute == null) return null;

    var hour = rawHour;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;

    return (hour, rawMinute);
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}
