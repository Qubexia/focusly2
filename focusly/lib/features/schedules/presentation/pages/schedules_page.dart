import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/services/schedule_focus_bus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/schedule_model.dart';
import '../bloc/schedules_cubit.dart';
import '../bloc/schedules_state.dart';
import '../widgets/create_schedule_sheet.dart';

class SchedulesPage extends StatelessWidget {
  const SchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SchedulesCubit()..loadSchedules(),
      child: const _SchedulesView(),
    );
  }
}

class _SchedulesView extends StatefulWidget {
  const _SchedulesView();

  @override
  State<_SchedulesView> createState() => _SchedulesViewState();
}

class _SchedulesViewState extends State<_SchedulesView> {
  CalendarFormat _calendarFormat = CalendarFormat.week;

  static final DateTime _calendarLastDay = DateTime.utc(2030, 12, 31);

  @override
  void initState() {
    super.initState();
    ScheduleFocusBus.instance.completed.addListener(_onScheduleCompleted);
  }

  @override
  void dispose() {
    ScheduleFocusBus.instance.completed.removeListener(_onScheduleCompleted);
    super.dispose();
  }

  void _onScheduleCompleted() {
    final completion = ScheduleFocusBus.instance.completed.value;
    if (completion == null || !mounted) return;
    context
        .read<SchedulesCubit>()
        .markScheduleCompletedLocally(completion.scheduleId, completion.date);
  }

  int _sessionMinutesFor(StudyScheduleModel schedule) {
    final end = schedule.endAt;
    if (end == null) return 120;
    final minutes = end.difference(schedule.startAt).inMinutes.abs();
    if (minutes <= 0) return 120;
    return minutes.clamp(30, 240);
  }

  void _openFocusForSchedule(BuildContext context, StudyScheduleModel schedule) {
    ScheduleFocusBus.instance.requestLaunch(
      ScheduleFocusLaunch(
        scheduleId: schedule.id,
        subjectId: schedule.subjectId.isEmpty ? null : schedule.subjectId,
        title: schedule.title,
        sessionMinutes: _sessionMinutesFor(schedule),
        date: SchedulesCubit.formatDate(_clampDay(context.read<SchedulesCubit>().state.focusedDay)),
      ),
    );
    // Switch to the Focus (Pomodoro) tab.
    context.go('/home?tab=2');
  }

  void _showAddScheduleSheet(BuildContext context, SchedulesState state) {
    final selectedDate = _clampDay(state.focusedDay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreateScheduleSheet(
        selectedDate: selectedDate,
        isSaving: state.isSaving,
        onSave: ({
          required daysOfWeek,
          required reminderEnabled,
          required reminderMinutesBefore,
          required startAt,
          required subjectId,
          required title,
          endAt,
        }) async {
          await context.read<SchedulesCubit>().createSchedule(
                subjectId: subjectId,
                title: title,
                startAt: startAt,
                endAt: endAt,
                daysOfWeek: daysOfWeek,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore,
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditScheduleSheet(
    BuildContext context,
    SchedulesState state,
    StudyScheduleModel schedule,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreateScheduleSheet(
        selectedDate: _clampDay(state.focusedDay),
        initialSchedule: schedule,
        isSaving: state.isSaving,
        onSave: ({
          required daysOfWeek,
          required reminderEnabled,
          required reminderMinutesBefore,
          required startAt,
          required subjectId,
          required title,
          endAt,
        }) async {
          await context.read<SchedulesCubit>().updateSchedule(
                id: schedule.id,
                subjectId: subjectId,
                title: title,
                startAt: startAt,
                endAt: endAt,
                daysOfWeek: daysOfWeek,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore,
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  StartingDayOfWeek _getStartingDayOfWeek() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return StartingDayOfWeek.monday;
      case DateTime.tuesday:
        return StartingDayOfWeek.tuesday;
      case DateTime.wednesday:
        return StartingDayOfWeek.wednesday;
      case DateTime.thursday:
        return StartingDayOfWeek.thursday;
      case DateTime.friday:
        return StartingDayOfWeek.friday;
      case DateTime.saturday:
        return StartingDayOfWeek.saturday;
      case DateTime.sunday:
        return StartingDayOfWeek.sunday;
      default:
        return StartingDayOfWeek.monday;
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime get _calendarFirstDay => _dateOnly(DateTime.now());

  DateTime _clampDay(DateTime day) {
    final normalizedDay = _dateOnly(day);
    if (normalizedDay.isBefore(_calendarFirstDay)) {
      return _calendarFirstDay;
    }
    if (normalizedDay.isAfter(_calendarLastDay)) {
      return _calendarLastDay;
    }
    return normalizedDay;
  }

  Future<bool?> _confirmDeleteSchedule(
    BuildContext context,
    StudyScheduleModel schedule,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.schedulesDeleteDialogTitle),
          content: Text(
            l10n.schedulesDeleteDialogMessage(schedule.title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<SchedulesCubit, SchedulesState>(
      listener: (context, state) {
        if (state.feedbackType != SchedulesFeedbackType.none &&
            state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: state.feedbackType == SchedulesFeedbackType.error
                  ? AppColors.error
                  : AppColors.secondary,
            ),
          );
          context.read<SchedulesCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.schedulesTitle),
            actions: [
              IconButton(
                onPressed: () => context.read<SchedulesCubit>().loadSchedules(),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCalendar(context, state, isDark),
              const SizedBox(height: 16),
              Expanded(
                child: _buildScheduleList(context, state, isDark),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              onPressed: () => _showAddScheduleSheet(context, state),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(
      BuildContext context, SchedulesState state, bool isDark) {
    final focusedDay = _clampDay(state.focusedDay);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: TableCalendar(
        firstDay: _calendarFirstDay,
        lastDay: _calendarLastDay,
        focusedDay: focusedDay,
        calendarFormat: _calendarFormat,
        enabledDayPredicate: (day) => !day.isBefore(_calendarFirstDay),
        selectedDayPredicate: (day) => isSameDay(focusedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          context.read<SchedulesCubit>().updateFocusedDay(selectedDay);
        },
        onPageChanged: (focusedDay) {
          context.read<SchedulesCubit>().updateFocusedDay(focusedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        startingDayOfWeek: _getStartingDayOfWeek(),
        daysOfWeekHeight: 32,
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          leftChevronIcon: Icon(Icons.chevron_left_rounded,
              color: isDark ? Colors.white : Colors.black87),
          rightChevronIcon: Icon(Icons.chevron_right_rounded,
              color: isDark ? Colors.white : Colors.black87),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.primary,
          ),
          formatButtonDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          formatButtonTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: AppColors.error.withValues(alpha: 0.8),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
          weekendTextStyle: TextStyle(
            color: AppColors.error.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
          ),
          disabledTextStyle: TextStyle(
            color: (isDark ? Colors.white : Colors.black54).withValues(alpha: 0.28),
            fontWeight: FontWeight.w500,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleList(
      BuildContext context, SchedulesState state, bool isDark) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final daySchedules = state.schedules.where((s) {
      final focusedApiWeekday = state.focusedDay.weekday % 7;
      return s.daysOfWeek.contains(focusedApiWeekday);
    }).toList();

    if (daySchedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.schedulesEmptyMessage,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showAddScheduleSheet(context, state),
              child: Text(l10n.schedulesEmptyAddFirst),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: daySchedules.length,
      itemBuilder: (context, index) {
        final schedule = daySchedules[index];
        final isCompleted = state.completedKeys.contains(
          SchedulesCubit.completionKey(schedule.id, state.focusedDay),
        );
        return _ScheduleTile(
          schedule: schedule,
          isCompleted: isCompleted,
          onTap: () => _openFocusForSchedule(context, schedule),
          onEdit: () => _showEditScheduleSheet(context, state, schedule),
          onDelete: () async {
            final shouldDelete = await _confirmDeleteSchedule(context, schedule);
            if (shouldDelete != true || !context.mounted) {
              return false;
            }

            return await context.read<SchedulesCubit>().deleteSchedule(schedule.id);
          },
        );
      },
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.isCompleted,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final StudyScheduleModel schedule;
  final bool isCompleted;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: ValueKey(schedule.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.commonDelete,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? AppColors.secondary.withValues(alpha: 0.6)
                  : isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isCompleted ? AppColors.secondary : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.book_rounded,
                  color: isCompleted ? AppColors.secondary : AppColors.primary,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(schedule.startAt)} - ${_formatTime(schedule.endAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (schedule.reminderEnabled)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: l10n.schedulesActionsTooltip,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      await onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.commonEdit),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.commonDelete),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
