import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../planner/data/models/planned_item_model.dart';
import '../../../planner/data/repositories/planner_repository.dart';
import '../../../pomodoro/data/models/pomodoro_today_model.dart';
import '../../../pomodoro/data/repositories/pomodoro_repository.dart';
import '../../../schedules/data/datasources/schedules_remote_datasource.dart';
import '../../../schedules/data/models/schedule_model.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';
import '../../../../core/utils/date_utils.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    SubjectsRepository? subjectsRepository,
    PomodoroRepository? pomodoroRepository,
    SchedulesRemoteDataSource? schedulesDataSource,
    PlannerRepository? plannerRepository,
  })  : _subjectsRepository = subjectsRepository ?? SubjectsRepository(),
        _pomodoroRepository = pomodoroRepository ?? PomodoroRepository(),
        _schedulesDataSource =
            schedulesDataSource ?? SchedulesRemoteDataSource(),
        _plannerRepository = plannerRepository ?? PlannerRepository(),
        super(const HomeState());

  final SubjectsRepository _subjectsRepository;
  final PomodoroRepository _pomodoroRepository;
  final SchedulesRemoteDataSource _schedulesDataSource;
  final PlannerRepository _plannerRepository;

  Future<void> loadHome() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final from = AppDateUtils.formatDate(startOfDay);
    final to = AppDateUtils.formatDate(endOfDay);

    try {
      final results = await Future.wait([
        _subjectsRepository.getSubjects(),
        _pomodoroRepository.getToday(),
        _schedulesDataSource.getSchedules(from: startOfDay, to: endOfDay),
        _plannerRepository.getItems(
          type: PlannedItemType.task,
          from: from,
          to: to,
        ),
      ]);

      final subjects = results[0] as List<SubjectModel>;
      final pomodoroToday = results[1] as PomodoroTodayModel;
      final schedules = results[2] as List<StudyScheduleModel>;
      final tasks = results[3] as List<PlannedItemModel>;

      final upcomingTasks = tasks
          .where((t) => !t.completed)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      emit(
        state.copyWith(
          isLoading: false,
          subjects: subjects,
          pomodoroToday: pomodoroToday,
          todaySchedules: schedules.where((s) => s.isActive).toList(),
          todayTasks: upcomingTasks.take(8).toList(),
        ),
      );
    } on DioException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: _extractMessage(e),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load home data.',
        ),
      );
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Something went wrong.';
    }
    return 'Something went wrong.';
  }
}
