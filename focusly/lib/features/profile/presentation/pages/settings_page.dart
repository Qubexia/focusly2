import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: const [SizedBox(height: 14), _SettingsActionsCard()],
        ),
      ),
    );
  }
}

class _SettingsActionsCard extends StatelessWidget {
  const _SettingsActionsCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          _SettingsActionTile(
            title: 'Edit Profile',
            subtitle: 'Update your name and avatar.',
            icon: Icons.draw_rounded,
            color: AppColors.primary,
            onTap: () => _showComingSoon(context, 'Edit Profile'),
          ),
          _SettingsActionTile(
            title: 'Notifications',
            subtitle: 'Manage reminders and alerts.',
            icon: Icons.notifications_active_outlined,
            color: AppColors.secondary,
            onTap: () => _showComingSoon(context, 'Notifications'),
          ),
          _SettingsActionTile(
            title: 'Go Premium',
            subtitle: 'Unlock full analytics and AI tools.',
            icon: Icons.auto_awesome_rounded,
            color: AppColors.premium,
            onTap: () => _showComingSoon(context, 'Premium'),
          ),
          _SettingsActionTile(
            title: 'Security',
            subtitle: 'Review sessions and device access.',
            icon: Icons.shield_moon_outlined,
            color: isDark ? AppColors.primaryLight : AppColors.textPrimaryLight,
            onTap: () => _showComingSoon(context, 'Security'),
          ),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
