import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../schedules/data/datasources/schedules_remote_datasource.dart';
import '../../../schedules/data/models/schedule_model.dart';
import '../../../schedules/presentation/widgets/create_schedule_sheet.dart';

/// Subject-scoped study schedule list with a shortcut to add recurring blocks.
class SubjectStudyScheduleSection extends StatefulWidget {
  const SubjectStudyScheduleSection({
    super.key,
    required this.subjectId,
    required this.accentColor,
  });

  final String subjectId;
  final Color accentColor;

  @override
  State<SubjectStudyScheduleSection> createState() =>
      _SubjectStudyScheduleSectionState();
}

class _SubjectStudyScheduleSectionState
    extends State<SubjectStudyScheduleSection> {
  final SchedulesRemoteDataSource _dataSource = SchedulesRemoteDataSource();
  List<StudyScheduleModel> _schedules = const [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final from = DateTime.now().subtract(const Duration(days: 7));
      final to = DateTime.now().add(const Duration(days: 90));
      final schedules = await _dataSource.getSchedules(from: from, to: to);
      if (!mounted) return;
      setState(() {
        _schedules = schedules
            .where((schedule) => schedule.subjectId == widget.subjectId)
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreateScheduleSheet(
        selectedDate: DateTime.now(),
        isSaving: _isSaving,
        lockedSubjectId: widget.subjectId,
        onSave: ({
          required subjectId,
          required title,
          required startAt,
          endAt,
          required daysOfWeek,
          required reminderMinutesBefore,
          required reminderEnabled,
        }) async {
          setState(() => _isSaving = true);
          try {
            await _dataSource.createSchedule(
              subjectId: subjectId,
              title: title,
              startAt: startAt,
              endAt: endAt,
              daysOfWeek: daysOfWeek,
              reminderMinutesBefore: reminderMinutesBefore,
              reminderEnabled: reminderEnabled,
            );
            if (sheetContext.mounted) Navigator.pop(sheetContext);
            await _load();
          } finally {
            if (mounted) setState(() => _isSaving = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.subjectsStudyScheduleTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: _isSaving ? null : _openCreateSheet,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.subjectsAddStudySchedule),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ))
        else if (_schedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Text(
              l10n.subjectsStudyScheduleEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          )
        else
          ..._schedules.map(
            (schedule) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: widget.accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: widget.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatTime(schedule.startAt)} · ${_daysLabel(schedule.daysOfWeek)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat.Hm().format(date);
  }

  String _daysLabel(List<int> days) {
    if (days.isEmpty) return '';
    final locale = Localizations.localeOf(context).toString();
    final narrowWeekday = DateFormat('EEE', locale);
    return days
        .map((day) => narrowWeekday.format(DateTime(2024, 1, 7 + day)))
        .join(', ');
  }
}
