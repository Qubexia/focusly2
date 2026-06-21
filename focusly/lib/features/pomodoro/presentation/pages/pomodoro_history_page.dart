import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/pomodoro_session_model.dart';
import '../../data/repositories/pomodoro_repository.dart';

class PomodoroHistoryPage extends StatefulWidget {
  const PomodoroHistoryPage({super.key});

  @override
  State<PomodoroHistoryPage> createState() => _PomodoroHistoryPageState();
}

class _PomodoroHistoryPageState extends State<PomodoroHistoryPage> {
  final PomodoroRepository _repository = PomodoroRepository();
  List<PomodoroSessionModel> _sessions = const [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));

    try {
      final sessions = await _repository.getHistory(
        from: AppDateUtils.formatDate(from),
        to: AppDateUtils.formatDate(now),
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pomodoroHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _hasError
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(l10n.pomodoroHistoryLoadError)),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton(
                          onPressed: _load,
                          child: Text(l10n.commonRetry),
                        ),
                      ),
                    ],
                  )
                : _sessions.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              l10n.pomodoroHistoryEmpty,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          return _HistoryTile(
                            session: session,
                            isDark: isDark,
                          );
                        },
                      ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.session, required this.isDark});

  final PomodoroSessionModel session;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat('MMM d, yyyy · HH:mm', locale)
        .format(session.startedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.timer_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pomodoroMinutesFocus(session.totalFocusMinutes),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          _StatusChip(status: session.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final normalized = status.toLowerCase();
    final color = normalized == 'completed'
        ? AppColors.secondary
        : normalized == 'aborted'
            ? AppColors.error
            : AppColors.primary;

    final label = switch (normalized) {
      'completed' => l10n.pomodoroStatusCompleted,
      'aborted' => l10n.pomodoroStatusAborted,
      'paused' => l10n.pomodoroStatusPaused,
      'active' => l10n.pomodoroStatusActive,
      _ => status,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
