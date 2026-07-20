import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zakerly/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';
import '../../data/models/planned_item_model.dart';

class CreatePlannedItemSheet extends StatefulWidget {
  const CreatePlannedItemSheet({
    super.key,
    required this.initialDate,
    required this.onSave,
    this.isSaving = false,
    this.lockedSubjectId,
  });

  final DateTime initialDate;
  final bool isSaving;

  /// When set, the sheet is scoped to this subject and hides the subject
  /// picker — every created item belongs to the given subject.
  final String? lockedSubjectId;
  final Function({
    required PlannedItemType type,
    required String title,
    String? notes,
    required DateTime date,
    String? time,
    String? subjectId,
    int? reminderMinutesBefore,
    String? recurrence,
    List<int>? daysOfWeek,
    DateTime? recurrenceEndAt,
  }) onSave;

  @override
  State<CreatePlannedItemSheet> createState() => _CreatePlannedItemSheetState();
}

class _CreatePlannedItemSheetState extends State<CreatePlannedItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  PlannedItemType _selectedType = PlannedItemType.task;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String? _selectedSubjectId;
  String _recurrence = 'once';

  /// Weekdays a weekly rule fires on, Sun=0..Sat=6 to match the API.
  List<int> _selectedDays = [];

  /// Optional last day of the recurrence. Null repeats indefinitely.
  DateTime? _recurrenceEndDate;

  /// Minutes-before-due to fire the reminder. `null` = no reminder, `0` = at
  /// the exact due time. Defaults to a 15-minute heads-up.
  int? _reminderMinutesBefore = 15;

  /// Reminder offsets offered in the picker (minutes before due).
  static const List<int?> _reminderOptions = [null, 0, 5, 15, 30, 60, 1440];
  
  List<SubjectModel> _subjects = [];
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedSubjectId = widget.lockedSubjectId;
    if (widget.lockedSubjectId == null) {
      _loadSubjects();
    } else {
      _isLoadingSubjects = false;
    }
  }

  /// Dart's Mon=1..Sun=7 mapped to the API's Sun=0..Sat=6.
  int _apiWeekday(DateTime date) => date.weekday % 7;

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        // A weekly rule with no day would never fire.
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays = [..._selectedDays, day]..sort();
      }
    });
  }

  Future<void> _pickRecurrenceEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _selectedDate,
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _recurrenceEndDate = picked);
  }

  Future<void> _loadSubjects() async {
    try {
      final repo = SubjectsRepository();
      final subjects = await repo.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoadingSubjects = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSubjects = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final l10n = AppLocalizations.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.plannerAddNewPlan,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Category Selection
              _SectionLabel(label: l10n.plannerCategory),
              const SizedBox(height: 12),
              Row(
                children: PlannedItemType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getIcon(type),
                              color: isSelected ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getTypeLabel(l10n, type),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              _SectionLabel(label: l10n.plannerDetails),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.plannerTitleLabel,
                  hintText: l10n.plannerTitleHint,
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? l10n.plannerTitleRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: l10n.plannerNotesLabel,
                  hintText: l10n.plannerNotesHint,
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: l10n.plannerSetDate),
                        const SizedBox(height: 8),
                        _PickerButton(
                          label: DateFormat.yMMMd(
                            Localizations.localeOf(context).toString(),
                          ).format(_selectedDate),
                          icon: Icons.event_rounded,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 1),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 2),
                              ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: l10n.plannerTime),
                        const SizedBox(height: 8),
                        _PickerButton(
                          label: _selectedTime?.format(context) ?? l10n.plannerSetTime,
                          icon: Icons.access_time_rounded,
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) setState(() => _selectedTime = time);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: l10n.plannerRecurrence),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _recurrence,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'once',
                    child: Text(l10n.plannerRecurrenceOnce),
                  ),
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text(l10n.plannerRecurrenceDaily),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(l10n.plannerRecurrenceWeekly),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _recurrence = value;
                    // Seed a weekly rule with the day the user already picked,
                    // so "أسبوعياً" alone still repeats on that weekday.
                    if (value == 'weekly' && _selectedDays.isEmpty) {
                      _selectedDays = [_apiWeekday(_selectedDate)];
                    }
                  });
                },
              ),
              if (_recurrence == 'weekly') ...[
                const SizedBox(height: 16),
                _SectionLabel(label: l10n.plannerRecurrenceDaysLabel),
                const SizedBox(height: 8),
                _DaysPicker(
                  selectedDays: _selectedDays,
                  onToggle: _toggleDay,
                ),
              ],
              if (_recurrence != 'once') ...[
                const SizedBox(height: 16),
                _SectionLabel(label: l10n.plannerRecurrenceEndLabel),
                const SizedBox(height: 8),
                _PickerButton(
                  label: _recurrenceEndDate == null
                      ? l10n.plannerRecurrenceEndNever
                      : DateFormat.yMMMd(
                          Localizations.localeOf(context).toString(),
                        ).format(_recurrenceEndDate!),
                  icon: Icons.event_repeat_rounded,
                  onTap: _pickRecurrenceEnd,
                ),
                if (_recurrenceEndDate != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _recurrenceEndDate = null),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(l10n.plannerRecurrenceEndClear),
                    ),
                  ),
              ],
              if (widget.lockedSubjectId == null) ...[
                const SizedBox(height: 16),
                _SectionLabel(label: l10n.plannerSubject),
                const SizedBox(height: 8),
                _isLoadingSubjects
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonFormField<String?>(
                        initialValue: _selectedSubjectId,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        hint: Text(l10n.plannerSubjectSelect),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(l10n.plannerSubjectGeneral),
                          ),
                          ..._subjects.map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                s.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedSubjectId = val),
                      ),
              ],

              const SizedBox(height: 24),
              _SectionLabel(label: l10n.plannerReminder),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _reminderMinutesBefore,
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(Icons.notifications_active_rounded, size: 20),
                ),
                items: _reminderOptions
                    .map((minutes) => DropdownMenuItem<int?>(
                          value: minutes,
                          child: Text(_reminderLabel(l10n, minutes)),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _reminderMinutesBefore = value),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isSaving ? null : _submit,
                  child: widget.isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.plannerSavePlan),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    widget.onSave(
      type: _selectedType,
      title: _titleController.text.trim(),
      notes: _notesController.text.trim(),
      date: _selectedDate,
      time: _selectedTime == null
          ? null
          : '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
              '${_selectedTime!.minute.toString().padLeft(2, '0')}',
      subjectId: _selectedSubjectId,
      reminderMinutesBefore: _reminderMinutesBefore,
      recurrence: _recurrence,
      daysOfWeek: _recurrence == 'weekly' ? _selectedDays : null,
      recurrenceEndAt: _recurrence == 'once' ? null : _recurrenceEndDate,
    );
  }

  String _reminderLabel(AppLocalizations l10n, int? minutes) {
    if (minutes == null) return l10n.plannerReminderOff;
    if (minutes == 0) return l10n.plannerReminderAtTime;
    if (minutes == 60) return l10n.plannerReminderHourBefore;
    if (minutes == 1440) return l10n.plannerReminderDayBefore;
    return l10n.plannerReminderMinutesBefore(minutes);
  }

  IconData _getIcon(PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task: return Icons.menu_book_rounded;
      case PlannedItemType.revision: return Icons.history_rounded;
      case PlannedItemType.lecture: return Icons.school_rounded;
      case PlannedItemType.exam: return Icons.assignment_late_rounded;
    }
  }

  String _getTypeLabel(AppLocalizations l10n, PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return l10n.plannerTypeTask;
      case PlannedItemType.revision:
        return l10n.plannerTypeRevision;
      case PlannedItemType.lecture:
        return l10n.plannerTypeLecture;
      case PlannedItemType.exam:
        return l10n.plannerTypeExam;
    }
  }
}

/// Weekday toggles for a weekly rule. Indexed in the API's Sun=0..Sat=6 space
/// so no conversion is needed between here and the request body.
class _DaysPicker extends StatelessWidget {
  const _DaysPicker({required this.selectedDays, required this.onToggle});

  final List<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final narrowWeekday = DateFormat('EEEEE', locale);
    // 2024-01-07 is a Sunday; offsetting by index yields Sun..Sat (day 0..6).
    final labels = List.generate(
      7,
      (index) => narrowWeekday.format(DateTime(2024, 1, 7 + index)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (day) {
        final isSelected = selectedDays.contains(day);
        return GestureDetector(
          onTap: () => onToggle(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
            child: Center(
              child: Text(
                labels[day],
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textTertiaryDark
            : AppColors.textTertiaryLight,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
