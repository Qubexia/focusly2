import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import 'home_page.dart';
import '../../../pomodoro/presentation/pages/pomodoro_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../planner/presentation/pages/planner_page.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../schedules/presentation/pages/schedules_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final Set<int> _loadedTabs = {0};

  final List<Widget Function()> _viewBuilders = [
    () => const HomeView(),
    () => const SchedulesPage(),
    () => const PomodoroPage(),
    () => const AnalyticsPage(),
    () => const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _loadedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        extendBody: true, // Allows content to flow behind the floating nav bar
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(_viewBuilders.length, (index) {
            if (!_loadedTabs.contains(index)) {
              return const SizedBox.shrink();
            }
            return _viewBuilders[index]();
          }),
        ),
        bottomNavigationBar: _FloatingBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
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
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => onItemTapped(0),
                ),
                _NavBarItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  isSelected: selectedIndex == 1,
                  onTap: () => onItemTapped(1),
                ),
                _NavBarItem(
                  icon: Icons.timer_rounded,
                  label: 'Focus',
                  isSelected: selectedIndex == 2,
                  onTap: () => onItemTapped(2),
                  isCenter: true,
                ),
                _NavBarItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  isSelected: selectedIndex == 3,
                  onTap: () => onItemTapped(3),
                ),
                _NavBarItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
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
