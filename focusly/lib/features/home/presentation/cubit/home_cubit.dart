import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../planner/data/models/planned_item_model.dart';
import '../../../planner/data/repositories/planner_repository.dart';
import '../../../planner/data/services/planner_reminder_sync.dart';
import '../../../pomodoro/data/models/pomodoro_today_model.dart';
import '../../../pomodoro/data/repositories/pomodoro_repository.dart';
import '../../../schedules/data/datasources/schedules_remote_datasource.dart';
import '../../../schedules/data/models/schedule_model.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';
import '../../../../core/localization/app_l10n.dart';
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
  final PlannerReminderSync _reminderSync = PlannerReminderSync();

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
          // "Upcoming today" must drop sessions whose time has already passed:
          // keep an item only while its end time-of-day is still ahead of now.
          todaySchedules: schedules.where((s) {
            if (!s.isActive) return false;
            final end = s.endAt ?? s.startAt;
            final endToday =
                DateTime(now.year, now.month, now.day, end.hour, end.minute);
            return endToday.isAfter(now);
          }).toList(),
          todayTasks: upcomingTasks.take(8).toList(),
        ),
      );

      unawaited(_syncUpcomingReminders(
        from,
        AppDateUtils.formatDate(now.add(const Duration(days: 7))),
      ));
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
          errorMessage: AppL10n.current.homeLoadFailed,
        ),
      );
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    return AppL10n.current.commonError;
  }

  Future<void> _syncUpcomingReminders(String from, String to) async {
    try {
      final results = await Future.wait([
        _plannerRepository.getItems(type: PlannedItemType.task, from: from, to: to),
        _plannerRepository.getItems(type: PlannedItemType.revision, from: from, to: to),
        _plannerRepository.getItems(type: PlannedItemType.lecture, from: from, to: to),
        _plannerRepository.getItems(type: PlannedItemType.exam, from: from, to: to),
      ]);
      await _reminderSync.syncItems([
        ...results[0],
        ...results[1],
        ...results[2],
        ...results[3],
      ]);
    } catch (_) {
      // Reminder sync is best-effort on home load.
    }
  }
}
