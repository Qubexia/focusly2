import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../cubit/ai_notes_cubit.dart';
import '../widgets/ai_job_groups.dart';

class AiNotesHubPage extends StatelessWidget {
  const AiNotesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final isPremium =
        auth is AuthAuthenticated && auth.user.isPremium;

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
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      children: [
                        if (state.isSubmitting) ...[
                          LinearProgressIndicator(value: state.jobProgress),
                          const SizedBox(height: 8),
                          const Text('Generating your study notes...'),
                          const SizedBox(height: 20),
                        ],
                        if (state.pickedImagePaths.isNotEmpty)
                          SizedBox(
                            height: 88,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: state.pickedImagePaths.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(state.pickedImagePaths[index]),
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => context
                                            .read<AiNotesCubit>()
                                            .removeImageAt(index),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          child: Icon(Icons.close, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: state.selectedSubjectId,
                          decoration: const InputDecoration(labelText: 'Subject'),
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
                        const SizedBox(height: 24),
                        Text(
                          'Study packs',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (state.isLoadingArtifacts)
                          const Center(child: CircularProgressIndicator())
                        else if (jobGroups.isEmpty)
                          const Text(
                            'No AI notes yet. Add photos and tap Generate.',
                          )
                        else
                          ...jobGroups.map(
                            (group) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.auto_stories_rounded,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  group.createdAt != null
                                      ? dateFormat.format(group.createdAt!)
                                      : 'Study pack',
                                ),
                                subtitle: Text(
                                  group.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () => context.push(
                                  '/ai-notes/viewer',
                                  extra: group.artifacts,
                                ),
                              ),
                            ),
                          ),
                      ],
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
