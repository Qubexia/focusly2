import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import 'home_page.dart';
import '../../../pomodoro/presentation/pages/pomodoro_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../schedules/presentation/pages/schedules_page.dart';
import '../../../streaks/presentation/cubit/streak_cubit.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Set<int> _loadedTabs = {0};

  /// Tabs stay alive inside the [IndexedStack], so a tab that shows remote
  /// stats needs to know when it becomes visible again to re-fetch them.
  final List<Widget Function(bool isActive)> _viewBuilders = [
    (_) => const HomeView(),
    (_) => const SchedulesPage(),
    (_) => const PomodoroPage(),
    (_) => const AnalyticsPage(),
    (isActive) => ProfilePage(isActive: isActive),
  ];

  int _selectedIndexFromRoute(BuildContext context) {
    final tab = int.tryParse(
      GoRouterState.of(context).uri.queryParameters['tab'] ?? '',
    );
    return (tab ?? widget.initialIndex).clamp(0, 4);
  }

  void _onItemTapped(int index) {
    context.go('/home?tab=$index');
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndexFromRoute(context);
    _loadedTabs.add(selectedIndex);

    return BlocProvider(
      create: (context) {
        final cubit = StreakCubit();
        if (context.read<AuthBloc>().state is AuthAuthenticated) {
          cubit.loadStreak();
        }
        return cubit;
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.read<StreakCubit>().loadStreak();
          }
          if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        child: Scaffold(
          extendBody: true, // Allows content to flow behind the floating nav bar
          body: IndexedStack(
            index: selectedIndex,
            children: List.generate(_viewBuilders.length, (index) {
              if (!_loadedTabs.contains(index)) {
                return const SizedBox.shrink();
              }
              return _viewBuilders[index](index == selectedIndex);
            }),
          ),
          bottomNavigationBar: _FloatingBottomNavBar(
            selectedIndex: selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class _FloatingBottomNavBar extends StatelessWidget {
  const _FloatingBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        bottomPadding > 0 ? bottomPadding : 10,
      ),
      height: 60,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.surfaceDark : Colors.white).withValues(
          alpha: 0.85,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: (isDark ? AppColors.borderDark : AppColors.borderLight)
              .withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.dashboard_rounded,
                  label: l10n.homeNavHome,
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                _NavBarItem(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.homeNavSchedule,
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),
                _NavBarItem(
                  icon: Icons.timer_rounded,
                  label: l10n.homeNavFocus,
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                  isCenter: true,
                ),
                _NavBarItem(
                  icon: Icons.bar_chart_rounded,
                  label: l10n.homeNavStats,
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                ),
                _NavBarItem(
                  icon: Icons.person_rounded,
                  label: l10n.homeNavProfile,
                  isSelected: selectedIndex == 4,
                  onTap: () => onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCenter = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.primary
        : (Theme.of(context).brightness == Brightness.dark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(icon, color: color, size: isCenter ? 28 : 24),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
