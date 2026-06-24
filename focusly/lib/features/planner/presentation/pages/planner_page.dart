import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/planned_item_model.dart';
import '../bloc/planner_cubit.dart';
import '../widgets/planned_item_tile.dart';
import '../widgets/create_planned_item_sheet.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlannerCubit()..loadDate(DateTime.now()),
      child: const _PlannerView(),
    );
  }
}

class _PlannerView extends StatefulWidget {
  const _PlannerView();

  @override
  State<_PlannerView> createState() => _PlannerViewState();
}

class _PlannerViewState extends State<_PlannerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddItemSheet(BuildContext context, PlannerState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CreatePlannedItemSheet(
        initialDate: state.selectedDate,
        isSaving: state.isSaving,
        onSave: ({
          required date,
          required title,
          required type,
          notes,
          subjectId,
          time,
        }) async {
          await context.read<PlannerCubit>().createItem(
                type: type,
                title: title,
                notes: notes,
                date: date,
                time: time,
                subjectId: subjectId,
              );
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

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
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.plannerTitle),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Column(
                children: [
                  _CalendarStrip(
                    selectedDate: state.selectedDate,
                    onDateSelected: (date) {
                      context.read<PlannerCubit>().loadDate(date);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: l10n.plannerTabTasks),
                    Tab(text: l10n.plannerTabRevisions),
                    Tab(text: l10n.plannerTabLectures),
                    Tab(text: l10n.plannerTabExams),
                  ],
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _PlannedItemsList(
                            items: state.tasks,
                            type: PlannedItemType.task,
                            emptyMessage: l10n.plannerEmptyTasks,
                          ),
                          _PlannedItemsList(
                            items: state.revisions,
                            type: PlannedItemType.revision,
                            emptyMessage: l10n.plannerEmptyRevisions,
                          ),
                          _PlannedItemsList(
                            items: state.lectures,
                            type: PlannedItemType.lecture,
                            emptyMessage: l10n.plannerEmptyLectures,
                          ),
                          _PlannedItemsList(
                            items: state.exams,
                            type: PlannedItemType.exam,
                            emptyMessage: l10n.plannerEmptyExams,
                          ),
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              onPressed: () => _showAddItemSheet(context, state),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        );
      },
    );
  }
}

class _CalendarStrip extends StatelessWidget {
  const _CalendarStrip({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    // Generate a range of 30 days starting from today
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    
    return SizedBox(
      height: 80,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 30, // Show next 30 days
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
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight)),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
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

class _PlannedItemsList extends StatelessWidget {
  const _PlannedItemsList({
    required this.items,
    required this.type,
    required this.emptyMessage,
  });

  final List<PlannedItemModel> items;
  final PlannedItemType type;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(type),
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return PlannedItemTile(
          item: items[index],
          onComplete: () => context.read<PlannerCubit>().completeItem(type, items[index].id),
          onDelete: () => context.read<PlannerCubit>().deleteItem(type, items[index].id),
        );
      },
    );
  }

  IconData _getIcon(PlannedItemType type) {
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
}
