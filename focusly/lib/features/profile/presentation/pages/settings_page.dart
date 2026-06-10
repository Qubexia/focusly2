import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../../subscription/presentation/subscription_actions.dart';
import '../widgets/edit_profile_sheet.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _profileDataSource = ProfileRemoteDataSource();
  NotificationPreferences _prefs = const NotificationPreferences();
  List<AuthSessionModel> _sessions = const [];
  bool _focusMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await _profileDataSource.getNotificationPreferences();
      final sessions = await _profileDataSource.getSessions();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotifications() async {
    await _profileDataSource.updateSettings(notifications: _prefs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification preferences saved')),
    );
  }

  Future<void> _toggleFocusMode(bool value) async {
    setState(() => _focusMode = value);
    await _profileDataSource.updateSettings(focusMode: value);
  }

  Future<void> _revokeSession(String id) async {
    await _profileDataSource.revokeSession(id);
    await _load();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your data. Type DELETE to confirm.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _profileDataSource.deleteAccount();
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _SectionHeader(title: 'Account'),
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit profile',
                      onTap: () => showEditProfileSheet(context, user),
                    ),
                    _SettingsTile(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Premium',
                      subtitle: user?.isPremium == true ? 'Active' : 'Upgrade',
                      onTap: () => context.push('/premium'),
                    ),
                    if (user?.isPremium == true)
                      _SettingsTile(
                        icon: Icons.cancel_outlined,
                        title: 'Cancel subscription',
                        subtitle: 'Stop renewal at period end',
                        onTap: () => SubscriptionActions.cancelFromContext(context),
                      ),
                    _SettingsTile(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Notes',
                      onTap: () => context.push('/ai-notes'),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Notifications'),
                    SwitchListTile(
                      title: const Text('Study reminders'),
                      value: _prefs.reminders,
                      onChanged: (v) {
                        setState(() => _prefs = _prefs.copyWith(reminders: v));
                        _saveNotifications();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Streak alerts'),
                      value: _prefs.streak,
                      onChanged: (v) {
                        setState(() => _prefs = _prefs.copyWith(streak: v));
                        _saveNotifications();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Product updates'),
                      value: _prefs.marketing,
                      onChanged: (v) {
                        setState(() => _prefs = _prefs.copyWith(marketing: v));
                        _saveNotifications();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionHeader(title: 'Focus'),
                    SwitchListTile(
                      title: const Text('Focus mode'),
                      subtitle: const Text('Reduce non-essential notifications'),
                      value: _focusMode,
                      onChanged: _toggleFocusMode,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Active devices'),
                    ..._sessions.map(
                      (session) => ListTile(
                        title: Text(session.deviceLabel),
                        subtitle: Text(
                          session.current ? 'This device' : 'Other device',
                        ),
                        trailing: session.current
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.logout_rounded),
                                onPressed: () => _revokeSession(session.id),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Danger zone'),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Log out'),
                      onTap: () =>
                          context.read<AuthBloc>().add(const AuthLogoutRequested()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                      title: const Text('Delete account', style: TextStyle(color: AppColors.error)),
                      onTap: _deleteAccount,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
