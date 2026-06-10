import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final summaryText = summary?.summaryText ?? '';
    final cardsCount = flashcards?.flashcards.length ?? 0;
    final questionsCount = questions?.questions.length ?? 0;
    final sectionCount = _parseSummarySections(summaryText).length;
    final isRtl = _looksArabic(
      [
        summaryText,
        ...(flashcards?.flashcards.expand(
              (card) => [
                (card['front'] ?? '').toString(),
                (card['back'] ?? '').toString(),
              ],
            ) ??
            const <String>[]),
        ...(questions?.questions.expand(
              (q) => [
                (q['question'] ?? q['prompt'] ?? '').toString(),
                (q['answer'] ?? '').toString(),
              ],
            ) ??
            const <String>[]),
      ].join(' '),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF4F8FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isRtl ? 'حزمة المراجعة' : 'Study Pack',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(
            artifact: summary,
            isRtl: isRtl,
            header: _PackHeader(
              summaryText: summaryText,
              sectionCount: sectionCount,
              flashcardsCount: cardsCount,
              questionsCount: questionsCount,
              isRtl: isRtl,
            ),
            tabBar: _StudyPackTabBar(controller: _tabs, isRtl: isRtl),
          ),
          _FlashcardsTab(
            artifact: flashcards,
            isRtl: isRtl,
            header: _PackHeader(
              summaryText: summaryText,
              sectionCount: sectionCount,
              flashcardsCount: cardsCount,
              questionsCount: questionsCount,
              isRtl: isRtl,
            ),
            tabBar: _StudyPackTabBar(controller: _tabs, isRtl: isRtl),
          ),
          _QuestionsTab(
            artifact: questions,
            isRtl: isRtl,
            header: _PackHeader(
              summaryText: summaryText,
              sectionCount: sectionCount,
              flashcardsCount: cardsCount,
              questionsCount: questionsCount,
              isRtl: isRtl,
            ),
            tabBar: _StudyPackTabBar(controller: _tabs, isRtl: isRtl),
          ),
        ],
      ),
    );
  }
}

class _PackHeader extends StatelessWidget {
  const _PackHeader({
    required this.summaryText,
    required this.sectionCount,
    required this.flashcardsCount,
    required this.questionsCount,
    required this.isRtl,
  });

  final String summaryText;
  final int sectionCount;
  final int flashcardsCount;
  final int questionsCount;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final readMinutes = (summaryText.length / 900).ceil().clamp(1, 99);
    final preview = summaryText
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .firstWhere((line) => line.length > 12, orElse: () => '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRtl ? 'محتوى جاهز للمراجعة' : 'Ready to review',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRtl
                            ? '$readMinutes د قراءة تقريبية'
                            : '~$readMinutes min read',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.5,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.article_outlined,
                    value: sectionCount > 0 ? '$sectionCount' : '—',
                    label: isRtl ? 'أقسام' : 'Sections',
                    isDarkCard: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.style_outlined,
                    value: '$flashcardsCount',
                    label: isRtl ? 'بطاقات' : 'Cards',
                    isDarkCard: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.quiz_outlined,
                    value: '$questionsCount',
                    label: isRtl ? 'أسئلة' : 'Quiz',
                    isDarkCard: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.isDarkCard,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool isDarkCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}

class _StudyPackTabBar extends StatelessWidget {
  const _StudyPackTabBar({required this.controller, required this.isRtl});

  final TabController controller;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : Colors.white;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: [
          Tab(
            height: 44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notes_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text(isRtl ? 'ملخص' : 'Summary'),
                ],
              ),
            ),
          ),
          Tab(
            height: 44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text(isRtl ? 'بطاقات' : 'Cards'),
                ],
              ),
            ),
          ),
          Tab(
            height: 44,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_rounded, size: 17),
                  const SizedBox(width: 6),
                  Text(isRtl ? 'اختبار' : 'Quiz'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({
    this.artifact,
    required this.isRtl,
    required this.header,
    required this.tabBar,
  });

  final AiArtifactModel? artifact;
  final bool isRtl;
  final Widget header;
  final Widget tabBar;

  @override
  Widget build(BuildContext context) {
    final text = artifact?.summaryText ?? '';
    if (text.isEmpty) {
      return _ScrollableStudyPackShell(
        header: header,
        tabBar: tabBar,
        child: _EmptyArtifactState(
          icon: Icons.notes_rounded,
          title: isRtl ? 'لا يوجد ملخص' : 'No summary yet',
          message: isRtl
              ? 'سيظهر الملخص هنا بعد توليد حزمة المراجعة.'
              : 'Your AI summary will appear here once generated.',
          isRtl: isRtl,
        ),
      );
    }

    final sections = _parseSummarySections(text);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: tabBar,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final section = sections[index];
              return _SurfaceCard(
                child: Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment:
                        isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (sections.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isRtl ? 'قسم ${index + 1}' : 'Section ${index + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ...section.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SummaryLine(
                            line: line,
                            isRtl: isRtl,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.line,
    required this.isRtl,
    required this.isDark,
  });

  final String line;
  final bool isRtl;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isBullet = line.startsWith('- ') || line.startsWith('• ');
    final content = isBullet ? line.substring(2).trim() : line;

    if (isBullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.75,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
            ),
          ),
        ],
      );
    }

    return Text(
      content,
      textAlign: isRtl ? TextAlign.right : TextAlign.left,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.75,
            fontSize: 16,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
    );
  }
}

class _FlashcardsTab extends StatefulWidget {
  const _FlashcardsTab({
    this.artifact,
    required this.isRtl,
    required this.header,
    required this.tabBar,
  });

  final AiArtifactModel? artifact;
  final bool isRtl;
  final Widget header;
  final Widget tabBar;

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab> {
  late final PageController _pageController;
  int _index = 0;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.selectionClick();
    setState(() => _showBack = !_showBack);
  }

  void _goTo(int index) {
    if (index < 0 || index >= (widget.artifact?.flashcards.length ?? 0)) {
      return;
    }
    setState(() {
      _index = index;
      _showBack = false;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.artifact?.flashcards ?? const [];
    if (cards.isEmpty) {
      return _ScrollableStudyPackShell(
        header: widget.header,
        tabBar: widget.tabBar,
        child: _EmptyArtifactState(
          icon: Icons.style_rounded,
          title: widget.isRtl ? 'لا توجد بطاقات' : 'No flashcards yet',
          message: widget.isRtl
              ? 'ستظهر بطاقات المراجعة هنا بعد التوليد.'
              : 'Flashcards will show up here once your pack is ready.',
          isRtl: widget.isRtl,
        ),
      );
    }

    final progress = (_index + 1) / cards.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: widget.header),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: widget.tabBar,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      widget.isRtl
                          ? 'بطاقة ${_index + 1} من ${cards.length}'
                          : 'Card ${_index + 1} of ${cards.length}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.cardDark
                        : AppColors.secondaryLight,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: (viewportHeight * 0.42).clamp(280.0, 420.0),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: cards.length,
                    onPageChanged: (index) => setState(() {
                      _index = index;
                      _showBack = false;
                    }),
                    itemBuilder: (context, pageIndex) {
                      final pageCard = cards[pageIndex];
                      final pageFront = (pageCard['front'] ?? pageCard['question'] ?? '')
                          .toString();
                      final pageBack =
                          (pageCard['back'] ?? pageCard['answer'] ?? '').toString();
                      final showingBack = pageIndex == _index && _showBack;
                      final displayText = showingBack ? pageBack : pageFront;

                      return GestureDetector(
                        onTap: pageIndex == _index ? _flipCard : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                          decoration: BoxDecoration(
                            gradient: showingBack ? AppColors.primaryGradient : null,
                            color: showingBack
                                ? null
                                : (isDark ? AppColors.cardDark : Colors.white),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: showingBack
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: showingBack ? 0.28 : 0.08,
                                ),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Directionality(
                            textDirection: widget.isRtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: showingBack
                                        ? Colors.white.withValues(alpha: 0.16)
                                        : AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    showingBack
                                        ? (widget.isRtl ? 'الإجابة' : 'Answer')
                                        : (widget.isRtl ? 'السؤال' : 'Question'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: showingBack
                                              ? Colors.white
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 220),
                                          transitionBuilder: (child, animation) =>
                                              FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                              scale: Tween<double>(begin: 0.96, end: 1)
                                                  .animate(animation),
                                              child: child,
                                            ),
                                          ),
                                          child: Text(
                                            displayText,
                                            key: ValueKey('$pageIndex-$showingBack'),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.45,
                                                  color: showingBack ? Colors.white : null,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 16,
                                      color: showingBack
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.isRtl
                                          ? (showingBack
                                              ? 'اضغط للعودة'
                                              : 'اضغط لإظهار الإجابة')
                                          : (showingBack
                                              ? 'Tap to hide answer'
                                              : 'Tap to reveal answer'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: showingBack
                                                ? Colors.white.withValues(alpha: 0.8)
                                                : AppColors.textSecondaryLight,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                        icon: Icon(
                          widget.isRtl
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          size: 18,
                        ),
                        label: Text(widget.isRtl ? 'السابق' : 'Previous'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _index < cards.length - 1
                            ? () => _goTo(_index + 1)
                            : null,
                        icon: Icon(
                          widget.isRtl
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label: Text(widget.isRtl ? 'التالي' : 'Next'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionsTab extends StatefulWidget {
  const _QuestionsTab({
    this.artifact,
    required this.isRtl,
    required this.header,
    required this.tabBar,
  });

  final AiArtifactModel? artifact;
  final bool isRtl;
  final Widget header;
  final Widget tabBar;

  @override
  State<_QuestionsTab> createState() => _QuestionsTabState();
}

class _QuestionsTabState extends State<_QuestionsTab> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final questions = widget.artifact?.questions ?? const [];
    if (questions.isEmpty) {
      return _ScrollableStudyPackShell(
        header: widget.header,
        tabBar: widget.tabBar,
        child: _EmptyArtifactState(
          icon: Icons.quiz_rounded,
          title: widget.isRtl ? 'لا توجد أسئلة' : 'No quiz questions yet',
          message: widget.isRtl
              ? 'ستظهر أسئلة التدريب هنا بعد التوليد.'
              : 'Practice questions will appear here once generated.',
          isRtl: widget.isRtl,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: widget.header),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: widget.tabBar,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList.separated(
            itemCount: questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final q = questions[index];
              final prompt =
                  (q['question'] ?? q['prompt'] ?? 'Question').toString();
              final answer = (q['answer'] ?? '').toString();
              final isExpanded = _expandedIndex == index;

              return _QuizCard(
                index: index,
                prompt: prompt,
                answer: answer,
                isExpanded: isExpanded,
                isRtl: widget.isRtl,
                onToggle: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _expandedIndex = isExpanded ? null : index;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScrollableStudyPackShell extends StatelessWidget {
  const _ScrollableStudyPackShell({
    required this.header,
    required this.tabBar,
    required this.child,
  });

  final Widget header;
  final Widget tabBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: tabBar,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: child,
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.index,
    required this.prompt,
    required this.answer,
    required this.isExpanded,
    required this.isRtl,
    required this.onToggle,
  });

  final int index;
  final String prompt;
  final String answer;
  final bool isExpanded;
  final bool isRtl;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Column(
          crossAxisAlignment:
              isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prompt,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  isExpanded
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(
                  isExpanded
                      ? (isRtl ? 'إخفاء الإجابة' : 'Hide answer')
                      : (isRtl ? 'إظهار الإجابة' : 'Show answer'),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Text(
                    answer.isEmpty
                        ? (isRtl ? 'لا توجد إجابة.' : 'No answer available.')
                        : answer,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.65,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _EmptyArtifactState extends StatelessWidget {
  const _EmptyArtifactState({
    required this.icon,
    required this.title,
    required this.message,
    required this.isRtl,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySection {
  const _SummarySection(this.lines);
  final List<String> lines;
}

List<_SummarySection> _parseSummarySections(String text) {
  final blocks = text
      .split(RegExp(r'\n\s*\n'))
      .map((block) => block.trim())
      .where((block) => block.isNotEmpty)
      .toList();

  if (blocks.isEmpty) return [const _SummarySection([])];

  return blocks
      .map(
        (block) => _SummarySection(
          block.split('\n').map((line) => line.trim()).where((l) => l.isNotEmpty).toList(),
        ),
      )
      .toList();
}

bool _looksArabic(String text) => RegExp(r'[\u0600-\u06FF]').hasMatch(text);
