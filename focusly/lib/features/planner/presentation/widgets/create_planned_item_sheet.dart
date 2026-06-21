import 'package:flutter/material.dart';
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
  });

  final DateTime initialDate;
  final bool isSaving;
  final Function({
    required PlannedItemType type,
    required String title,
    String? notes,
    required DateTime date,
    String? time,
    String? subjectId,
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
  
  List<SubjectModel> _subjects = [];
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: l10n.plannerSubject),
                        const SizedBox(height: 8),
                        _isLoadingSubjects
                            ? const Center(child: LinearProgressIndicator())
                            : DropdownButtonFormField<String?>(
                                initialValue: _selectedSubjectId,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                hint: Text(l10n.plannerSubjectSelect),
                                items: [
                                  DropdownMenuItem(value: null, child: Text(l10n.plannerSubjectGeneral)),
                                  ..._subjects.map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                                      )),
                                ],
                                onChanged: (val) => setState(() => _selectedSubjectId = val),
                              ),
                      ],
                    ),
                  ),
                ],
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
      time: _selectedTime?.format(context),
      subjectId: _selectedSubjectId,
    );
  }

  IconData _getIcon(PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task: return Icons.task_alt_rounded;
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
