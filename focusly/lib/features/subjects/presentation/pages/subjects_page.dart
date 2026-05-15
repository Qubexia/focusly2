import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
        final authState = context.watch<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;
        final countLabel = user?.isPremium == true
            ? '${state.subjects.length} active subjects'
            : '${state.subjects.length}/3 free subjects';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Subjects'),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isSaving
                ? null
                : () => _openEditorSheet(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Subject'),
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
                        'Build your study map',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Organize each subject with its own color, icon, and daily target.',
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
    if (state.isLoading && state.subjects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.subjects.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _SubjectsEmptyState(
            title: 'Could not load subjects',
            description: state.errorMessage!,
            actionLabel: 'Try Again',
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
            title: 'No subjects yet',
            description:
                'Create your first subject to start tracking study progress and daily goals.',
            actionLabel: 'Create Subject',
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
      );
      return;
    }

    await cubit.updateSubject(
      id: subject.id,
      name: draft.name,
      color: draft.colorHex,
      icon: draft.iconKey,
      dailyTargetMinutes: draft.dailyTargetMinutes,
    );
  }

  Future<void> _confirmDelete(BuildContext context, SubjectModel subject) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Archive subject?'),
          content: Text(
            '“${subject.name}” will be removed from the active subjects list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Archive'),
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Free plan limit reached',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        );
      },
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
                            '${subject.dailyTargetMinutes} min daily target',
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Archive')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      '${subject.progressPercent}%',
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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject?.name ?? '');
    _dailyTargetMinutes = (widget.subject?.dailyTargetMinutes ?? 60).toDouble();
    _selectedColorHex =
        widget.subject?.color ?? _SubjectPalette.options.first.hex;
    _selectedIconKey = widget.subject?.icon ?? _SubjectIconCatalog.options.first.key;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  isEditing ? 'Edit Subject' : 'Create Subject',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a subject name, a distinct icon, and a realistic daily goal.',
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
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'Physics 101',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject name';
                    }
                    if (value.trim().length < 2) {
                      return 'Subject name is too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Color',
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
                  'Icon',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Target',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_dailyTargetMinutes.round()} min',
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
                  label: '${_dailyTargetMinutes.round()} min',
                  onChanged: (value) => setState(() => _dailyTargetMinutes = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(isEditing ? 'Save Changes' : 'Create Subject'),
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
  });

  final String name;
  final String colorHex;
  final String iconKey;
  final int dailyTargetMinutes;
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
