import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../../streaks/presentation/cubit/streak_cubit.dart';
import '../../../streaks/presentation/cubit/streak_state.dart';
import '../../../subscription/presentation/subscription_actions.dart';
import '../widgets/edit_profile_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      },
      builder: (context, state) {
        final user = state is AuthAuthenticated ? state.user : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                onPressed: () => context.push('/profile/settings'),
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeroCard(user: user),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: 'Overview',
                    subtitle:
                        'A quick snapshot of your account and study pace.',
                  ),
                  const SizedBox(height: 14),
                  _InfoListCard(
                    children: [
                      _InfoTile(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Total Points',
                        value: '${user?.totalPoints ?? 0}',
                        color: AppColors.premium,
                      ),
                      BlocBuilder<StreakCubit, StreakState>(
                        builder: (context, streakState) {
                          final streakDays = streakState.current;
                          return _InfoTile(
                            icon: Icons.local_fire_department_rounded,
                            title: 'Current Streak',
                            value:
                                '$streakDays day${streakDays == 1 ? '' : 's'}',
                            color: AppColors.primary,
                          );
                        },
                      ),
                      const _InfoTile(
                        icon: Icons.timer_outlined,
                        title: 'Focus Sessions',
                        value: '24',
                        color: AppColors.primary,
                      ),
                      _InfoTile(
                        icon: Icons.verified_rounded,
                        title: 'Plan Status',
                        value: user?.isPremium == true ? 'Premium' : 'Free',
                        color: user?.isPremium == true
                            ? AppColors.premium
                            : AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    title: 'Account',
                    subtitle:
                        'Email, verification, subscription, and sign out.',
                  ),
                  const SizedBox(height: 14),
                  _InfoListCard(
                    children: [
                      _InfoTile(
                        icon: Icons.alternate_email_rounded,
                        title: 'Email Address',
                        value: user?.email ?? 'No email available',
                      ),
                      _VerificationTile(
                        verified: user?.emailVerified ?? false,
                      ),
                      _InfoTile(
                        icon: Icons.star_outline_rounded,
                        title: 'Current Plan',
                        value: _planLabel(user),
                      ),
                      _InfoActionTile(
                        icon: Icons.checklist_rounded,
                        title: 'Daily Planner',
                        subtitle: 'Tasks, revisions, lectures, and exams.',
                        onTap: () => context.push('/planner'),
                      ),
                      _InfoActionTile(
                        icon: Icons.auto_awesome_rounded,
                        title: 'AI Notes',
                        subtitle: 'Generate summaries and flashcards.',
                        onTap: () => context.push('/ai-notes'),
                      ),
                      _InfoActionTile(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Premium',
                        subtitle: _planLabel(user),
                        onTap: () => context.push('/premium'),
                      ),
                      if (user?.isPremium == true)
                        _InfoActionTile(
                          icon: Icons.cancel_outlined,
                          title: 'Cancel subscription',
                          subtitle: 'Stop renewal at the end of the billing period',
                          onTap: () => SubscriptionActions.cancelFromContext(context),
                        ),
                      _InfoActionTile(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Manage account actions and preferences.',
                        onTap: () => context.push('/profile/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Material(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            leading: Container(
                              height: 42,
                              width: 42,
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: AppColors.error,
                              ),
                            ),
                            title: Text(
                              'Log Out',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Sign out from this device.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _confirmLogout(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _planLabel(UserModel? user) {
    if (user == null) return 'Free plan';
    return user.isPremium ? 'Premium plan' : 'Free plan';
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text(
            'You will need to sign in again to access your study dashboard.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = user?.name.isNotEmpty == true ? user!.name : 'Zakerly Student';
    final email = user?.email ?? 'student@Zakerly.app';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withValues(
              alpha: 0.18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(user: user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroBadge(
                icon: user?.isPremium == true
                    ? Icons.workspace_premium_rounded
                    : Icons.eco_outlined,
                label: user?.isPremium == true ? 'Premium' : 'Free',
              ),
              _HeroBadge(
                icon: (user?.emailVerified ?? false)
                    ? Icons.verified_rounded
                    : Icons.mark_email_unread_outlined,
                label: (user?.emailVerified ?? false)
                    ? 'Verified'
                    : 'Unverified',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your account is ready for focused sessions, structured planning, and long-term progress tracking.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showEditProfileSheet(context, user),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.draw_rounded),
                  label: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user?.avatarUrl?.isNotEmpty == true;

    return Container(
      height: 82,
      width: 82,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        backgroundImage: hasAvatar ? NetworkImage(user!.avatarUrl!) : null,
        child: hasAvatar
            ? null
            : const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 30,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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


class _InfoListCard extends StatelessWidget {
  const _InfoListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _VerificationTile extends StatefulWidget {
  const _VerificationTile({required this.verified});

  final bool verified;

  @override
  State<_VerificationTile> createState() => _VerificationTileState();
}

class _VerificationTileState extends State<_VerificationTile> {
  final AuthRepository _authRepository = AuthRepository();
  bool _sending = false;

  Future<void> _resend() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await _authRepository.resendVerificationEmail();
      if (!mounted) return;
      _showSnack(
        'Verification email sent. Check your inbox.',
        AppColors.secondary,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(_errorMessage(e), AppColors.error);
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'Could not send the email. Please try again.',
        AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _errorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? 'Could not send the email.';
    }
    return 'Could not send the email. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final verified = widget.verified;
    final tileColor = verified ? AppColors.secondary : Colors.orange;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: tileColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          verified ? Icons.verified_user_rounded : Icons.verified_user_outlined,
          color: tileColor,
        ),
      ),
      title: Text(
        'Verification',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        verified ? 'Verified' : 'Pending — verify to secure your account.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      trailing: verified
          ? null
          : _sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _resend,
                  child: const Text('Resend'),
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileColor = color ?? AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: tileColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: tileColor),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _InfoActionTile extends StatelessWidget {
  const _InfoActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
