import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/chapter_model.dart';
import '../../data/models/subject_model.dart';
import '../cubit/subject_detail_cubit.dart';

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({required this.subjectId, super.key});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubjectDetailCubit()..load(subjectId),
      child: const _SubjectDetailView(),
    );
  }
}

class _SubjectDetailView extends StatelessWidget {
  const _SubjectDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubjectDetailCubit, SubjectDetailState>(
      listener: (context, state) {
        if (state.feedbackType == SubjectDetailFeedbackType.none ||
            state.feedbackMessage == null) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.feedbackMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.read<SubjectDetailCubit>().clearFeedback();
      },
      builder: (context, state) {
        final subject = state.subject;
        final progress = state.progress;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(subject?.name ?? 'Subject Detail'),
            actions: [
              if (subject != null)
                IconButton(
                  onPressed: () => _openSubjectEditor(context, subject),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          floatingActionButton: subject == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: state.isSaving
                      ? null
                      : () => _openChapterEditor(context),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Chapter'),
                ),
          body: state.isLoading && subject == null
              ? const Center(child: CircularProgressIndicator())
              : state.errorMessage != null && subject == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<SubjectDetailCubit>().load(subject!.id),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                        children: [
                          if (subject != null) ...[
                            _SubjectOverviewCard(
                              subject: subject,
                              progressPercent: progress?.progressPercent ?? 0,
                              chaptersCompleted:
                                  progress?.chaptersCompleted ?? 0,
                              chaptersTotal: progress?.chaptersTotal ?? 0,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Chapters',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track the units you have finished and keep momentum visible.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (state.chapters.isEmpty)
                            _SubjectEmptyChapters(
                              onPressed: () => _openChapterEditor(context),
                            )
                          else
                            ...state.chapters.map(
                              (chapter) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ChapterTile(
                                  chapter: chapter,
                                  onChanged: (value) {
                                    context
                                        .read<SubjectDetailCubit>()
                                        .toggleChapter(
                                          chapter,
                                          value ?? false,
                                        );
                                  },
                                  onEdit: () => _openChapterEditor(
                                    context,
                                    chapter: chapter,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Future<void> _openChapterEditor(
    BuildContext context, {
    ChapterModel? chapter,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TextEditorSheet(
        title: chapter == null ? 'Add Chapter' : 'Edit Chapter',
        hintText: 'Chapter title',
        initialValue: chapter?.title ?? '',
        submitLabel: chapter == null ? 'Add Chapter' : 'Save Changes',
      ),
    );

    if (result == null || !context.mounted) return;

    if (chapter == null) {
      await context.read<SubjectDetailCubit>().createChapter(result);
    } else {
      await context.read<SubjectDetailCubit>().renameChapter(
            chapterId: chapter.id,
            title: result,
          );
    }
  }

  Future<void> _openSubjectEditor(
    BuildContext context,
    SubjectModel subject,
  ) async {
    final draft = await showModalBottomSheet<_SubjectDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SubjectEditorSheet(subject: subject),
    );

    if (draft == null || !context.mounted) return;

    await context.read<SubjectDetailCubit>().updateSubject(
          name: draft.name,
          color: draft.colorHex,
          icon: draft.iconKey,
          dailyTargetMinutes: draft.dailyTargetMinutes,
        );
  }
}

class _SubjectOverviewCard extends StatelessWidget {
  const _SubjectOverviewCard({
    required this.subject,
    required this.progressPercent,
    required this.chaptersCompleted,
    required this.chaptersTotal,
  });

  final SubjectModel subject;
  final int progressPercent;
  final int chaptersCompleted;
  final int chaptersTotal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _SubjectPalette.resolveColor(subject.color);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  _SubjectIconCatalog.iconForKey(subject.icon),
                  color: accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.dailyTargetMinutes} minutes planned every day',
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Progress',
                  value: '$progressPercent%',
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OverviewStat(
                  label: 'Chapters Done',
                  value: '$chaptersCompleted/$chaptersTotal',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (progressPercent.clamp(0, 100)) / 100,
              minHeight: 12,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

class _SubjectEmptyChapters extends StatelessWidget {
  const _SubjectEmptyChapters({required this.onPressed});

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
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No chapters yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Break the subject into clear chapters so progress becomes easier to track.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              child: const Text('Add First Chapter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.onChanged,
    required this.onEdit,
  });

  final ChapterModel chapter;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: chapter.completed,
          onChanged: onChanged,
          activeColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          chapter.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                decoration:
                    chapter.completed ? TextDecoration.lineThrough : null,
              ),
        ),
        subtitle: Text(
          chapter.completed ? 'Completed' : 'In progress',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: chapter.completed
                    ? AppColors.secondary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    );
  }
}

class _TextEditorSheet extends StatefulWidget {
  const _TextEditorSheet({
    required this.title,
    required this.hintText,
    required this.initialValue,
    required this.submitLabel,
  });

  final String title;
  final String hintText;
  final String initialValue;
  final String submitLabel;

  @override
  State<_TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<_TextEditorSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: widget.hintText,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: Text(widget.submitLabel),
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
    Navigator.of(context).pop(_controller.text.trim());
  }
}

class _SubjectEditorSheet extends StatefulWidget {
  const _SubjectEditorSheet({required this.subject});

  final SubjectModel subject;

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
    _nameController = TextEditingController(text: widget.subject.name);
    _dailyTargetMinutes = widget.subject.dailyTargetMinutes.toDouble();
    _selectedColorHex =
        widget.subject.color ?? _SubjectPalette.options.first.hex;
    _selectedIconKey =
        widget.subject.icon ?? _SubjectIconCatalog.options.first.key;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Edit Subject',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Update the subject identity, color, icon, and daily target.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject name';
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
                                ? (isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight)
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
                    child: const Text('Save Changes'),
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
