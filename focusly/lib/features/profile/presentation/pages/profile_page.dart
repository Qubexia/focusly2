import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

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
            title: Text(l10n.profileTitle),
            actions: [
              IconButton(
                onPressed: () => context.push('/profile/settings'),
                icon: const Icon(Icons.settings_outlined),
                tooltip: l10n.profileSettings,
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
                    title: l10n.profileOverviewTitle,
                    subtitle: l10n.profileOverviewSubtitle,
                  ),
                  const SizedBox(height: 14),
                  _InfoListCard(
                    children: [
                      _InfoTile(
                        icon: Icons.workspace_premium_rounded,
                        title: l10n.profileTotalPoints,
                        value: '${user?.totalPoints ?? 0}',
                        color: AppColors.premium,
                      ),
                      BlocBuilder<StreakCubit, StreakState>(
                        builder: (context, streakState) {
                          final streakDays = streakState.current;
                          return _InfoTile(
                            icon: Icons.local_fire_department_rounded,
                            title: l10n.profileCurrentStreak,
                            value: l10n.profileStreakDays(streakDays),
                            color: AppColors.primary,
                          );
                        },
                      ),
                      _InfoTile(
                        icon: Icons.timer_outlined,
                        title: l10n.profileFocusSessions,
                        value: '24',
                        color: AppColors.primary,
                      ),
                      _InfoTile(
                        icon: Icons.verified_rounded,
                        title: l10n.profilePlanStatus,
                        value: user?.isPremium == true
                            ? l10n.profilePremium
                            : l10n.profileFree,
                        color: user?.isPremium == true
                            ? AppColors.premium
                            : AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(
                    title: l10n.profileAccountTitle,
                    subtitle: l10n.profileAccountSubtitle,
                  ),
                  const SizedBox(height: 14),
                  _InfoListCard(
                    children: [
                      _InfoTile(
                        icon: Icons.alternate_email_rounded,
                        title: l10n.profileEmailAddress,
                        value: user?.email ?? l10n.profileNoEmail,
                      ),
                      _VerificationTile(
                        verified: user?.emailVerified ?? false,
                      ),
                      _InfoTile(
                        icon: Icons.star_outline_rounded,
                        title: l10n.profileCurrentPlan,
                        value: _planLabel(context, user),
                      ),
                      _InfoActionTile(
                        icon: Icons.checklist_rounded,
                        title: l10n.profileDailyPlanner,
                        subtitle: l10n.profileDailyPlannerSubtitle,
                        onTap: () => context.push('/planner'),
                      ),
                      _InfoActionTile(
                        icon: Icons.auto_awesome_rounded,
                        title: l10n.profileAiNotes,
                        subtitle: l10n.profileAiNotesSubtitle,
                        onTap: () => context.push('/ai-notes'),
                      ),
                      _InfoActionTile(
                        icon: Icons.workspace_premium_rounded,
                        title: l10n.profilePremium,
                        subtitle: _planLabel(context, user),
                        onTap: () => context.push('/premium'),
                      ),
                      if (user?.isPremium == true)
                        _InfoActionTile(
                          icon: Icons.cancel_outlined,
                          title: l10n.profileCancelSubscription,
                          subtitle: l10n.profileCancelSubscriptionSubtitle,
                          onTap: () => SubscriptionActions.cancelFromContext(context),
                        ),
                      _InfoActionTile(
                        icon: Icons.settings_outlined,
                        title: l10n.profileSettings,
                        subtitle: l10n.profileSettingsSubtitle,
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
                              l10n.profileLogout,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              l10n.profileLogoutSubtitle,
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

  static String _planLabel(BuildContext context, UserModel? user) {
    final l10n = AppLocalizations.of(context);
    if (user == null) return l10n.profileFreePlan;
    return user.isPremium ? l10n.profilePremiumPlan : l10n.profileFreePlan;
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.profileLogoutTitle),
          content: Text(l10n.profileLogoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.profileLogout),
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
    final l10n = AppLocalizations.of(context);
    final name = user?.name.isNotEmpty == true
        ? user!.name
        : l10n.profileDefaultName;
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
                label: user?.isPremium == true
                    ? l10n.profilePremium
                    : l10n.profileFree,
              ),
              _HeroBadge(
                icon: (user?.emailVerified ?? false)
                    ? Icons.verified_rounded
                    : Icons.mark_email_unread_outlined,
                label: (user?.emailVerified ?? false)
                    ? l10n.profileVerified
                    : l10n.profileUnverified,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.profileHeroDescription,
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
                  label: Text(l10n.profileEditProfile),
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
    final l10n = AppLocalizations.of(context);
    setState(() => _sending = true);
    try {
      await _authRepository.resendVerificationEmail();
      if (!mounted) return;
      _showSnack(
        l10n.profileVerificationEmailSent,
        AppColors.secondary,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(
        _errorMessage(e, l10n.profileVerificationEmailError),
        AppColors.error,
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        l10n.profileVerificationEmailError,
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

  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? fallback;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
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
        l10n.profileVerification,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        verified ? l10n.profileVerified : l10n.profileVerificationPending,
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
                  child: Text(l10n.profileResend),
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
