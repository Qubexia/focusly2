import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/config/platform_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/premium_gate_sheet.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../data/models/subject_model.dart';
import '../cubit/subjects_cubit.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubjectsCubit()..loadSubjects(),
      child: const _SubjectsView(),
    );
  }
}

class _SubjectsView extends StatelessWidget {
  const _SubjectsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<SubjectsCubit, SubjectsState>(
      listener: (context, state) {
        if (state.feedbackType == SubjectsFeedbackType.none ||
            state.feedbackMessage == null) {
          return;
        }

        if (state.feedbackType == SubjectsFeedbackType.premiumGate) {
          _showPremiumGate(context, state.feedbackMessage!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        context.read<SubjectsCubit>().clearFeedback();
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final authState = context.watch<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;
        final countLabel = user?.isPremium == true
            ? l10n.subjectsActiveCount(state.subjects.length)
            : l10n
                .subjectsFreeCount(state.subjects.length)
                .replaceFirst('/3', '/${PlatformConfig.current.freeSubjectLimit}');

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.subjectsTitle),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isSaving
                ? null
                : () => _openEditorSheet(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.subjectsNewSubject),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.darkGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.subjectsHeroTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.subjectsHeroSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          countLabel,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<SubjectsCubit>().loadSubjects(),
                  child: _buildBody(context, state),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SubjectsState state) {
    final l10n = AppLocalizations.of(context);

    if (state.isLoading && state.subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.subjects.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _SubjectsEmptyState(
            title: l10n.subjectsLoadErrorTitle,
            description: state.errorMessage!,
            actionLabel: l10n.commonRetry,
            onPressed: () => context.read<SubjectsCubit>().loadSubjects(),
          ),
        ],
      );
    }

    if (state.subjects.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _SubjectsEmptyState(
            title: l10n.subjectsEmptyTitle,
            description: l10n.subjectsEmptyDescription,
            actionLabel: l10n.subjectsCreateSubject,
            onPressed: () => _openEditorSheet(context),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: state.subjects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final subject = state.subjects[index];
        return _SubjectCard(
          subject: subject,
          onTap: () => context.push('/subjects/${subject.id}'),
          onEdit: () => _openEditorSheet(context, subject: subject),
          onDelete: () => _confirmDelete(context, subject),
        );
      },
    );
  }

  Future<void> _openEditorSheet(
    BuildContext context, {
    SubjectModel? subject,
  }) async {
    final draft = await showModalBottomSheet<_SubjectDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SubjectEditorSheet(subject: subject),
    );

    if (draft == null || !context.mounted) return;

    final cubit = context.read<SubjectsCubit>();
    if (subject == null) {
      await cubit.createSubject(
        name: draft.name,
        color: draft.colorHex,
        icon: draft.iconKey,
        dailyTargetMinutes: draft.dailyTargetMinutes,
        goalType: draft.goalType,
        goalDays: draft.goalDays,
      );
      return;
    }

    await cubit.updateSubject(
      id: subject.id,
      name: draft.name,
      color: draft.colorHex,
      icon: draft.iconKey,
      dailyTargetMinutes: draft.dailyTargetMinutes,
      goalType: draft.goalType,
      goalDays: draft.goalDays,
    );
  }

  Future<void> _confirmDelete(BuildContext context, SubjectModel subject) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.subjectsArchiveTitle),
          content: Text(
            l10n.subjectsArchiveMessage(subject.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.subjectsArchive),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      await context.read<SubjectsCubit>().deleteSubject(subject.id);
    }
  }

  void _showPremiumGate(BuildContext context, String message) {
    showPremiumGateSheet(
      context,
      title: AppLocalizations.of(context).subjectsFreeLimitTitle,
      message: message,
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectModel subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _SubjectPalette.resolveColor(subject.color);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _SubjectIconCatalog.iconForKey(subject.icon),
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subject.goalType == 'weekly'
                                ? l10n.subjectsWeeklyTargetLabel(
                                    subject.dailyTargetMinutes,
                                  )
                                : l10n.subjectsDailyTargetLabel(
                                    subject.dailyTargetMinutes,
                                  ),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.commonEdit),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.subjectsArchive),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.subjectsProgressLabel,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      l10n.subjectsPercentValue(subject.progressPercent),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (subject.progressPercent.clamp(0, 100)) / 100,
                    minHeight: 10,
                    backgroundColor: accentColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectsEmptyState extends StatelessWidget {
  const _SubjectsEmptyState({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectEditorSheet extends StatefulWidget {
  const _SubjectEditorSheet({this.subject});

  final SubjectModel? subject;

  @override
  State<_SubjectEditorSheet> createState() => _SubjectEditorSheetState();
}

class _SubjectEditorSheetState extends State<_SubjectEditorSheet> {
  late final TextEditingController _nameController;
  late double _dailyTargetMinutes;
  late String _selectedColorHex;
  late String _selectedIconKey;
  late String _goalType;
  late List<int> _goalDays;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _dailyTargetMinutes = (widget.subject?.dailyTargetMinutes ?? 60).toDouble();
    _selectedColorHex =
        widget.subject?.color ?? _SubjectPalette.options.first.hex;
    _selectedIconKey = widget.subject?.icon ?? _SubjectIconCatalog.options.first.key;
    _goalType = widget.subject?.goalType == 'daily' ? 'daily' : 'weekly';
    _goalDays = List<int>.from(widget.subject?.goalDays ?? const []);
  }

  void _toggleGoalDay(int day) {
    setState(() {
      if (_goalDays.contains(day)) {
        _goalDays.remove(day);
      } else {
        _goalDays.add(day);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.subject != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing
                      ? l10n.subjectsEditSubject
                      : l10n.subjectsCreateSubject,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.subjectsEditorSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.subjectsSubjectNameLabel,
                    hintText: l10n.subjectsSubjectNameHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.subjectsNameRequired;
                    }
                    if (value.trim().length < 2) {
                      return l10n.subjectsNameTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.subjectsColorLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _SubjectPalette.options.map((option) {
                    final isSelected = option.hex == _selectedColorHex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorHex = option.hex),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: option.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: option.color.computeLuminance() > 0.55
                                    ? AppColors.textPrimaryLight
                                    : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.subjectsIconLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _SubjectIconCatalog.options.map((option) {
                    final isSelected = option.key == _selectedIconKey;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconKey = option.key),
                      child: Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.14)
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                          ),
                        ),
                        child: Icon(
                          option.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _GoalTypeToggle(
                  goalType: _goalType,
                  isDark: isDark,
                  onChanged: (value) => setState(() => _goalType = value),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.subjectsDailyTarget,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.subjectsMinutesValue(_dailyTargetMinutes.round()),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _dailyTargetMinutes,
                  min: 15,
                  max: 240,
                  divisions: 15,
                  label: l10n.subjectsMinutesValue(_dailyTargetMinutes.round()),
                  onChanged: (value) => setState(() => _dailyTargetMinutes = value),
                ),
                if (_goalType == 'weekly') ...[
                  const SizedBox(height: 8),
                  _GoalDaysPicker(
                    selectedDays: _goalDays,
                    isDark: isDark,
                    onToggle: _toggleGoalDay,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(
                      isEditing
                          ? l10n.subjectsSaveChanges
                          : l10n.subjectsCreateSubject,
                    ),
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
    Navigator.of(context).pop(
      _SubjectDraft(
        name: _nameController.text.trim(),
        colorHex: _selectedColorHex,
        iconKey: _selectedIconKey,
        dailyTargetMinutes: _dailyTargetMinutes.round(),
        goalType: _goalType,
        goalDays: (_goalDays.toList()..sort()),
      ),
    );
  }
}

class _SubjectDraft {
  const _SubjectDraft({
    required this.name,
    required this.colorHex,
    required this.iconKey,
    required this.dailyTargetMinutes,
    required this.goalType,
    required this.goalDays,
  });

  final String name;
  final String colorHex;
  final String iconKey;
  final int dailyTargetMinutes;
  final String goalType;
  final List<int> goalDays;
}

class _GoalTypeToggle extends StatelessWidget {
  const _GoalTypeToggle({
    required this.goalType,
    required this.isDark,
    required this.onChanged,
  });

  final String goalType;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _segment(l10n.subjectsGoalDaily, 'daily'),
          _segment(l10n.subjectsGoalWeekly, 'weekly'),
        ],
      ),
    );
  }

  Widget _segment(String label, String value) {
    final selected = goalType == value;
    return Expanded(
      child: GestureDetector(
        onTap: selected ? null : () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalDaysPicker extends StatelessWidget {
  const _GoalDaysPicker({
    required this.selectedDays,
    required this.isDark,
    required this.onToggle,
  });

  final List<int> selectedDays;
  final bool isDark;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final narrowWeekday = DateFormat('EEEEE', locale);
    final labels = List.generate(
      7,
      (index) => narrowWeekday.format(DateTime(2024, 1, 7 + index)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () => onToggle(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SubjectColorOption {
  const _SubjectColorOption({required this.hex, required this.color});

  final String hex;
  final Color color;
}

class _SubjectPalette {
  static final List<_SubjectColorOption> options = [
    ...AppColors.subjectColors.map(
      (color) => _SubjectColorOption(
        hex: _toHex(color),
        color: color,
      ),
    ),
  ];

  static Color resolveColor(String? hex) {
    for (final option in options) {
      if (option.hex == hex) return option.color;
    }
    return AppColors.primary;
  }

  static String _toHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _SubjectIconOption {
  const _SubjectIconOption({
    required this.key,
    required this.icon,
  });

  final String key;
  final IconData icon;
}

class _SubjectIconCatalog {
  static const List<_SubjectIconOption> options = [
    _SubjectIconOption(key: 'book', icon: Icons.menu_book_rounded),
    _SubjectIconOption(key: 'calculate', icon: Icons.calculate_rounded),
    _SubjectIconOption(key: 'science', icon: Icons.science_rounded),
    _SubjectIconOption(key: 'language', icon: Icons.language_rounded),
    _SubjectIconOption(key: 'palette', icon: Icons.palette_outlined),
    _SubjectIconOption(key: 'code', icon: Icons.code_rounded),
  ];

  static IconData iconForKey(String? key) {
    for (final option in options) {
      if (option.key == key) return option.icon;
    }
    return Icons.menu_book_rounded;
  }
}
