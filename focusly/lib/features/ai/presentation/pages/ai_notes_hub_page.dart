import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
      return Scaffold(
        appBar: AppBar(title: const Text('AI Notes')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 64, color: AppColors.premium),
                const SizedBox(height: 16),
                const Text(
                  'AI Notes are a Premium feature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.push('/premium'),
                  child: const Text('Upgrade to Premium'),
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

  Future<void> _showImageSourceSheet(BuildContext context) async {
    final cubit = context.read<AiNotesCubit>();
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (source == 'gallery') {
      await cubit.pickFromGallery();
    } else if (source == 'camera') {
      await cubit.pickFromCamera();
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
        final viewer = state.viewerArtifacts;
        if (viewer != null && viewer.isNotEmpty) {
          context.read<AiNotesCubit>().clearViewerNavigation();
          context.push('/ai-notes/viewer', extra: viewer);
        }
      },
      builder: (context, state) {
        final jobGroups = groupArtifactsByJob(state.artifacts);
        final dateFormat = DateFormat.MMMd().add_jm();
        final selectedSubject = state.subjects
            .where((subject) => subject.id == state.selectedSubjectId)
            .cast<dynamic>()
            .firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Notes'),
            actions: [
              IconButton(
                onPressed: () => _showImageSourceSheet(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ],
          ),
          floatingActionButton: state.isSubmitting
              ? null
              : FloatingActionButton.extended(
                  onPressed: state.pickedImagePaths.isEmpty
                      ? () => _showImageSourceSheet(context)
                      : () => context.read<AiNotesCubit>().submitJob(),
                  icon: Icon(
                    state.pickedImagePaths.isEmpty
                        ? Icons.camera_alt_rounded
                        : Icons.auto_awesome_rounded,
                  ),
                  label: Text(
                    state.pickedImagePaths.isEmpty
                        ? 'Add photos'
                        : 'Generate (${state.pickedImagePaths.length})',
                  ),
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
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                        children: [
                          _HubHeroCard(
                            subjectName: selectedSubject?.name ?? 'Your subject',
                            selectedCount: state.pickedImagePaths.length,
                            isSubmitting: state.isSubmitting,
                            progress: state.jobProgress,
                          ),
                          const SizedBox(height: 18),
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Build a fresh study pack',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pick a subject, attach lecture photos, then generate a cleaner AI recap with cards and quiz questions.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.6),
                                ),
                                const SizedBox(height: 18),
                                DropdownButtonFormField<String>(
                                  initialValue: state.selectedSubjectId,
                                  decoration:
                                      const InputDecoration(labelText: 'Subject'),
                                  items: state.subjects
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text(s.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (id) {
                                    if (id != null) {
                                      context.read<AiNotesCubit>().selectSubject(id);
                                    }
                                  },
                                ),
                                if (state.isSubmitting) ...[
                                  const SizedBox(height: 18),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(value: state.jobProgress),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Generating your study notes...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                                if (state.pickedImagePaths.isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    height: 96,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: state.pickedImagePaths.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) {
                                        return _PickedImageTile(
                                          path: state.pickedImagePaths[index],
                                          onRemove: () => context
                                              .read<AiNotesCubit>()
                                              .removeImageAt(index),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Recent study packs',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Open any pack to review the summary, flashcards, and practice questions in a richer layout.',
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
                                child: _PackListCard(
                                  title: group.createdAt != null
                                      ? dateFormat.format(group.createdAt!)
                                      : 'Study pack',
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
                                  onTap: () => context.push(
                                    '/ai-notes/viewer',
                                    extra: group.artifacts,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Create a subject first, then generate AI notes for it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAddSubject,
              child: const Text('Go to Subjects'),
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
    required this.selectedCount,
    required this.isSubmitting,
    required this.progress,
  });

  final String subjectName;
  final int selectedCount;
  final bool isSubmitting;
  final double progress;

  @override
  Widget build(BuildContext context) {
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
            'AI Notes Studio',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Exclusive, modern packs built from your study material',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Subject: $subjectName',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(icon: Icons.photo_library_rounded, label: '$selectedCount photos'),
              _HeroBadge(
                icon: isSubmitting ? Icons.hourglass_top_rounded : Icons.auto_awesome_rounded,
                label: isSubmitting ? '${(progress * 100).round()}% generating' : 'Ready to generate',
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

class _PickedImageTile extends StatelessWidget {
  const _PickedImageTile({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Colors.black.withValues(alpha: 0.65),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
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
    required this.onTap,
  });

  final String title;
  final String preview;
  final int flashcardsCount;
  final int questionsCount;
  final bool isRtl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                _InfoPill(label: '$flashcardsCount cards'),
                _InfoPill(label: '$questionsCount questions'),
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
    return const _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_empty_rounded, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'No AI notes yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Add photos and generate your first exclusive study pack.',
          ),
        ],
      ),
    );
  }
}

bool _looksArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
