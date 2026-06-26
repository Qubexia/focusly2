import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/premium/premium_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../subscription/presentation/cubit/subscription_cubit.dart';
import '../cubit/ai_notes_cubit.dart';
import '../widgets/ai_job_groups.dart';

class AiNotesHubPage extends StatelessWidget {
  const AiNotesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final subscription = context.watch<SubscriptionCubit>().state.subscription;
    final isPremium = hasPremiumAccess(
      authState: auth,
      subscription: subscription,
    );

    if (!isPremium) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.aiNotesTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.premium),
                const SizedBox(height: 16),
                Text(
                  l10n.aiPremiumFeature,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.push('/premium'),
                  child: Text(l10n.aiUpgradeToPremium),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => AiNotesCubit()..loadHub(),
      child: const _AiNotesHubView(),
    );
  }
}

class _AiNotesHubView extends StatelessWidget {
  const _AiNotesHubView();

  Future<void> _confirmDeletePack(
    BuildContext context,
    AiJobGroup group,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiDeletePackTitle),
        content: Text(l10n.aiDeletePackMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AiNotesCubit>().deleteJobPack(group.jobId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiNotesCubit, AiNotesState>(
      listener: (context, state) {
        if (state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.feedbackMessage!)),
          );
          context.read<AiNotesCubit>().clearFeedback();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final jobGroups = groupArtifactsByJob(state.artifacts);
        final dateFormat = DateFormat.MMMd().add_jm();
        final selectedSubject = state.subjects
            .where((subject) => subject.id == state.selectedSubjectId)
            .cast<dynamic>()
            .firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.aiNotesTitle),
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.subjects.isEmpty
                  ? _EmptySubjects(onAddSubject: () => context.push('/subjects'))
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: Theme.of(context).brightness == Brightness.dark
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF08111E),
                                  AppColors.backgroundDark,
                                  Color(0xFF10213A),
                                ],
                              )
                            : const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFF7FAFF),
                                  Color(0xFFEAF3FF),
                                  Colors.white,
                                ],
                              ),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        children: [
                          _HubHeroCard(
                            subjectName:
                                selectedSubject?.name ?? l10n.aiYourSubject,
                            packsCount: jobGroups.length,
                          ),
                          const SizedBox(height: 18),
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.aiBrowsePacksTitle,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.aiBrowsePacksSubtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.6),
                                ),
                                const SizedBox(height: 18),
                                DropdownButtonFormField<String>(
                                  initialValue: state.selectedSubjectId,
                                  isExpanded: true,
                                  decoration:
                                      InputDecoration(labelText: l10n.aiSubjectLabel),
                                  items: state.subjects
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text(
                                            s.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      context.read<AiNotesCubit>().selectSubject(id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.aiRecentPacksTitle,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.aiRecentPacksSubtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          if (state.isLoadingArtifacts)
                            const Center(child: CircularProgressIndicator())
                          else if (jobGroups.isEmpty)
                            const _HubEmptyPacks()
                          else
                            ...jobGroups.map(
                              (group) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Dismissible(
                                  key: ValueKey(group.jobId),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) async {
                                    await _confirmDeletePack(context, group);
                                    return false;
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  child: _PackListCard(
                                    title: group.createdAt != null
                                        ? dateFormat.format(group.createdAt!)
                                        : l10n.aiStudyPack,
                                    preview: group.preview,
                                    flashcardsCount: group.artifacts
                                        .where((artifact) => artifact.kind == 'flashcards')
                                        .fold<int>(
                                          0,
                                          (total, artifact) =>
                                              total + artifact.flashcards.length,
                                        ),
                                    questionsCount: group.artifacts
                                        .where((artifact) => artifact.kind == 'questions')
                                        .fold<int>(
                                          0,
                                          (total, artifact) =>
                                              total + artifact.questions.length,
                                        ),
                                    isRtl: _looksArabic(group.preview),
                                    isDeleting: state.deletingJobId == group.jobId,
                                    onTap: () => context.push(
                                      '/ai-notes/viewer',
                                      extra: group.artifacts,
                                    ),
                                    onDelete: () => _confirmDeletePack(context, group),
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
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects({required this.onAddSubject});

  final VoidCallback onAddSubject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.aiNoSubjectsMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAddSubject,
              child: Text(l10n.aiGoToSubjects),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubHeroCard extends StatelessWidget {
  const _HubHeroCard({
    required this.subjectName,
    required this.packsCount,
  });

  final String subjectName;
  final int packsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiNotesStudio,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiNotesStudioSubtitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.aiSubjectName(subjectName),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(
                icon: Icons.auto_stories_rounded,
                label: l10n.aiPacksCount(packsCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PackListCard extends StatelessWidget {
  const _PackListCard({
    required this.title,
    required this.preview,
    required this.flashcardsCount,
    required this.questionsCount,
    required this.isRtl,
    required this.isDeleting,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String preview;
  final int flashcardsCount;
  final int questionsCount;
  final bool isRtl;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: isDeleting ? null : onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (isDeleting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    tooltip: l10n.aiDeletePackTooltip,
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 14),
            Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPill(label: l10n.aiCardsCount(flashcardsCount)),
                _InfoPill(label: l10n.aiQuestionsCount(questionsCount)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _HubEmptyPacks extends StatelessWidget {
  const _HubEmptyPacks();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            l10n.aiNoNotesYet,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(l10n.aiNoNotesYetHint),
        ],
      ),
    );
  }
}

bool _looksArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
