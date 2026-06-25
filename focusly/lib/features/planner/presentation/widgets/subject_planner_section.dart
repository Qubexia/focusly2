import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/planned_item_model.dart';
import '../bloc/planner_cubit.dart';
import 'create_planned_item_sheet.dart';
import 'planned_item_tile.dart';

/// The daily planner embedded inside a subject page. Every item it shows or
/// creates is scoped to [subjectId]; there is no longer a global planner page.
class SubjectPlannerSection extends StatelessWidget {
  const SubjectPlannerSection({
    super.key,
    required this.subjectId,
    required this.accentColor,
  });

  final String subjectId;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PlannerCubit(subjectId: subjectId)..loadDate(DateTime.now()),
      child: _SubjectPlannerView(accentColor: accentColor),
    );
  }
}

class _SubjectPlannerView extends StatefulWidget {
  const _SubjectPlannerView({required this.accentColor});

  final Color accentColor;

  @override
  State<_SubjectPlannerView> createState() => _SubjectPlannerViewState();
}

class _SubjectPlannerViewState extends State<_SubjectPlannerView> {
  PlannedItemType _selectedCategory = PlannedItemType.task;

  void _showAddItemSheet(BuildContext context, PlannerState state) {
    final cubit = context.read<PlannerCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreatePlannedItemSheet(
        initialDate: state.selectedDate,
        isSaving: state.isSaving,
        lockedSubjectId: cubit.subjectId,
        onSave: ({
          required date,
          required title,
          required type,
          notes,
          subjectId,
          time,
          reminderMinutesBefore,
        }) async {
          await cubit.createItem(
            type: type,
            title: title,
            notes: notes,
            date: date,
            time: time,
            subjectId: subjectId,
            reminderMinutesBefore: reminderMinutesBefore,
          );
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  List<PlannedItemModel> _itemsFor(PlannerState state, PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return state.tasks;
      case PlannedItemType.revision:
        return state.revisions;
      case PlannedItemType.lecture:
        return state.lectures;
      case PlannedItemType.exam:
        return state.exams;
    }
  }

  String _categoryLabel(AppLocalizations l10n, PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return l10n.plannerTabTasks;
      case PlannedItemType.revision:
        return l10n.plannerTabRevisions;
      case PlannedItemType.lecture:
        return l10n.plannerTabLectures;
      case PlannedItemType.exam:
        return l10n.plannerTabExams;
    }
  }

  String _emptyMessage(AppLocalizations l10n, PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return l10n.plannerEmptyTasks;
      case PlannedItemType.revision:
        return l10n.plannerEmptyRevisions;
      case PlannedItemType.lecture:
        return l10n.plannerEmptyLectures;
      case PlannedItemType.exam:
        return l10n.plannerEmptyExams;
    }
  }

  IconData _categoryIcon(PlannedItemType type) {
    switch (type) {
      case PlannedItemType.task:
        return Icons.task_alt_rounded;
      case PlannedItemType.revision:
        return Icons.history_rounded;
      case PlannedItemType.lecture:
        return Icons.school_rounded;
      case PlannedItemType.exam:
        return Icons.assignment_late_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<PlannerCubit, PlannerState>(
      listener: (context, state) {
        if (state.feedbackType != PlannerFeedbackType.none &&
            state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              behavior: SnackBarBehavior.floating,
              backgroundColor: state.feedbackType == PlannerFeedbackType.error
                  ? AppColors.error
                  : AppColors.secondary,
            ),
          );
          context.read<PlannerCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        final items = _itemsFor(state, _selectedCategory);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.plannerTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextButton.icon(
                  onPressed: () => _showAddItemSheet(context, state),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.plannerAddNewPlan),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CalendarStrip(
              selectedDate: state.selectedDate,
              accentColor: widget.accentColor,
              onDateSelected: (date) =>
                  context.read<PlannerCubit>().loadDate(date),
            ),
            const SizedBox(height: 12),
            Row(
              children: PlannedItemType.values.map((type) {
                final isSelected = _selectedCategory == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.accentColor
                            : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? widget.accentColor
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _categoryIcon(type),
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : widget.accentColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _categoryLabel(l10n, type),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              _EmptyPlannerCard(
                icon: _categoryIcon(_selectedCategory),
                message: _emptyMessage(l10n, _selectedCategory),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlannedItemTile(
                    item: item,
                    onComplete: () => context
                        .read<PlannerCubit>()
                        .completeItem(_selectedCategory, item.id),
                    onDelete: () => context
                        .read<PlannerCubit>()
                        .deleteItem(_selectedCategory, item.id),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyPlannerCard extends StatelessWidget {
  const _EmptyPlannerCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
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

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({
    required this.selectedDate,
    required this.onDateSelected,
    required this.accentColor,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    // Generate a range of 30 days starting from today.
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 30,
        itemBuilder: (context, index) {
          final date = start.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, today);
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? accentColor
                      : (isToday
                          ? accentColor.withValues(alpha: 0.5)
                          : (isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight)),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E(Localizations.localeOf(context).toString())
                        .format(date)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.8)
                          : (isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
