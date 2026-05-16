import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../../../subjects/data/repositories/subjects_repository.dart';

class CreateScheduleSheet extends StatefulWidget {
  const CreateScheduleSheet({
    super.key,
    required this.selectedDate,
    required this.onSave,
    this.isSaving = false,
  });

  final DateTime selectedDate;
  final bool isSaving;
  final Function({
    required String subjectId,
    required String title,
    required DateTime startAt,
    DateTime? endAt,
    required List<int> daysOfWeek,
    required int reminderMinutesBefore,
    required bool reminderEnabled,
  }) onSave;

  @override
  State<CreateScheduleSheet> createState() => _CreateScheduleSheetState();
}

class _CreateScheduleSheetState extends State<CreateScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String? _selectedSubjectId;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final List<int> _selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri by default
  bool _reminderEnabled = true;
  int _reminderOffset = 15;

  List<SubjectModel> _subjects = [];
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final repo = SubjectsRepository();
      final subjects = await repo.getSubjects();
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoadingSubjects = false;
          if (subjects.isNotEmpty) {
            _selectedSubjectId = subjects.first.id;
          }
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
    super.dispose();
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  bool _isPastStartTime(TimeOfDay time) {
    final now = DateTime.now();
    if (!_isSameDay(widget.selectedDate, now)) {
      return false;
    }

    final selectedDateTime = _combineDateAndTime(widget.selectedDate, time);
    return selectedDateTime.isBefore(now);
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                      'Create Study Block',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Subject'),
                const SizedBox(height: 12),
                _isLoadingSubjects
                    ? const Center(child: LinearProgressIndicator())
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedSubjectId,
                        decoration: const InputDecoration(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        hint: const Text('Select Subject'),
                        items: _subjects
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSubjectId = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Block Title'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Deep Work Session',
                  ),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Selected Day'),
                const SizedBox(height: 12),
                _InfoChip(
                  icon: Icons.event_rounded,
                  label: _formatDate(widget.selectedDate),
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Time Range'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        label: 'Starts at ${_startTime.format(context)}',
                        icon: Icons.login_rounded,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time == null) return;
                          if (_isPastStartTime(time)) {
                            _showValidationMessage(
                              'You cannot choose a start time before the current time.',
                            );
                            return;
                          }

                          setState(() {
                            _startTime = time;
                            if (!_combineDateAndTime(widget.selectedDate, _endTime)
                                .isAfter(_combineDateAndTime(widget.selectedDate, _startTime))) {
                              _endTime = TimeOfDay(
                                hour: (time.hour + 1) % 24,
                                minute: time.minute,
                              );
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerButton(
                        label: 'Ends at ${_endTime.format(context)}',
                        icon: Icons.logout_rounded,
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (time == null) return;
                          final selectedEnd = _combineDateAndTime(
                            widget.selectedDate,
                            time,
                          );
                          final selectedStart = _combineDateAndTime(
                            widget.selectedDate,
                            _startTime,
                          );

                          if (!selectedEnd.isAfter(selectedStart)) {
                            _showValidationMessage(
                              'End time must be after start time.',
                            );
                            return;
                          }

                          setState(() => _endTime = time);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionLabel(label: 'Days of Week'),
                const SizedBox(height: 12),
                _DaysPicker(
                  selectedDays: _selectedDays,
                  onToggle: _toggleDay,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel(label: 'Reminders'),
                    Switch.adaptive(
                      value: _reminderEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _reminderEnabled = val),
                    ),
                  ],
                ),
                if (_reminderEnabled) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _reminderOffset,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('At start time')),
                      DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                      DropdownMenuItem(
                          value: 15, child: Text('15 minutes before')),
                      DropdownMenuItem(
                          value: 30, child: Text('30 minutes before')),
                    ],
                    onChanged: (val) => setState(() => _reminderOffset = val ?? 15),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.isSaving ? null : _submit,
                    child: widget.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Schedule'),
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
    if (!_formKey.currentState!.validate() || _selectedSubjectId == null) return;

    final today = _dateOnly(DateTime.now());
    final selectedDay = _dateOnly(widget.selectedDate);

    if (selectedDay.isBefore(today)) {
      _showValidationMessage('You cannot create a schedule for a past day.');
      return;
    }

    final start = _combineDateAndTime(selectedDay, _startTime);
    final end = _combineDateAndTime(selectedDay, _endTime);

    if (_isSameDay(selectedDay, today) && start.isBefore(DateTime.now())) {
      _showValidationMessage(
        'You cannot create a schedule with a start time before the current time.',
      );
      return;
    }

    if (!end.isAfter(start)) {
      _showValidationMessage('End time must be after start time.');
      return;
    }

    widget.onSave(
      subjectId: _selectedSubjectId!,
      title: _titleController.text.trim(),
      startAt: start,
      endAt: end,
      daysOfWeek: _selectedDays,
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: _reminderOffset,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = monthNames[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}

class _DaysPicker extends StatelessWidget {
  const _DaysPicker({required this.selectedDays, required this.onToggle});
  final List<int> selectedDays;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = index + 1;
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
                labels[index],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton(
      {required this.label, required this.icon, required this.onTap});
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
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
