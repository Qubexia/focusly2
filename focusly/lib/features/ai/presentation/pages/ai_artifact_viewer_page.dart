import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/ai_artifact_model.dart';

class AiArtifactViewerPage extends StatefulWidget {
  const AiArtifactViewerPage({super.key, required this.artifacts});

  final List<AiArtifactModel> artifacts;

  @override
  State<AiArtifactViewerPage> createState() => _AiArtifactViewerPageState();
}

class _AiArtifactViewerPageState extends State<AiArtifactViewerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  AiArtifactModel? _byKind(String kind) {
    for (final a in widget.artifacts) {
      if (a.kind == kind) return a;
    }
    return widget.artifacts.isNotEmpty ? widget.artifacts.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _byKind('summary');
    final flashcards = _byKind('flashcards');
    final questions = _byKind('questions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study pack'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Cards'),
            Tab(text: 'Quiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(artifact: summary),
          _FlashcardsTab(artifact: flashcards),
          _QuestionsTab(artifact: questions),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({this.artifact});

  final AiArtifactModel? artifact;

  @override
  Widget build(BuildContext context) {
    final text = artifact?.summaryText ?? '';
    if (text.isEmpty) {
      return const Center(child: Text('No summary available.'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [Text(text, style: const TextStyle(height: 1.5, fontSize: 16))],
    );
  }
}

class _FlashcardsTab extends StatefulWidget {
  const _FlashcardsTab({this.artifact});

  final AiArtifactModel? artifact;

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab> {
  int _index = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final cards = widget.artifact?.flashcards ?? const [];
    if (cards.isEmpty) {
      return const Center(child: Text('No flashcards yet.'));
    }
    final card = cards[_index.clamp(0, cards.length - 1)];
    final front = (card['front'] ?? card['question'] ?? '').toString();
    final back = (card['back'] ?? card['answer'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    _showBack ? back : front,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_index + 1} / ${cards.length}'),
              Row(
                children: [
                  IconButton(
                    onPressed: _index > 0
                        ? () => setState(() {
                              _index--;
                              _showBack = false;
                            })
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    onPressed: _index < cards.length - 1
                        ? () => setState(() {
                              _index++;
                              _showBack = false;
                            })
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionsTab extends StatelessWidget {
  const _QuestionsTab({this.artifact});

  final AiArtifactModel? artifact;

  @override
  Widget build(BuildContext context) {
    final questions = artifact?.questions ?? const [];
    if (questions.isEmpty) {
      return const Center(child: Text('No questions yet.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: questions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final q = questions[index];
        return ExpansionTile(
          title: Text((q['question'] ?? q['prompt'] ?? 'Question').toString()),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text((q['answer'] ?? '').toString()),
              ),
            ),
          ],
        );
      },
    );
  }
}
