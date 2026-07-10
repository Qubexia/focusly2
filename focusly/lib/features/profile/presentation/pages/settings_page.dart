import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/localization/locale_cubit.dart';
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
      final focusMode = await _profileDataSource.getFocusMode();
      final sessions = await _profileDataSource.getSessions();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _focusMode = focusMode;
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
      SnackBar(content: Text(AppLocalizations.of(context).settingsNotificationsSaved)),
    );
  }

  Future<void> _showLanguagePicker() async {
    final cubit = context.read<LocaleCubit>();
    final l10n = AppLocalizations.of(context);
    final current = cubit.state?.languageCode;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: RadioGroup<String?>(
          groupValue: current,
          onChanged: (value) {
            cubit.setLocale(value == null ? null : Locale(value));
            Navigator.pop(ctx);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.settingsLanguageTile,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              RadioListTile<String?>(
                value: null,
                title: Text(l10n.languageSystemDefault),
              ),
              RadioListTile<String?>(
                value: 'en',
                title: Text(l10n.languageEnglish),
              ),
              RadioListTile<String?>(
                value: 'ar',
                title: Text(l10n.languageArabic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _languageLabel(AppLocalizations l10n, Locale? locale) {
    switch (locale?.languageCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'ar':
        return l10n.languageArabic;
      default:
        return l10n.languageSystemDefault;
    }
  }

  Future<void> _toggleFocusMode(bool value) async {
    setState(() => _focusMode = value);
    try {
      await _profileDataSource.updateSettings(focusMode: value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _focusMode = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).commonError)),
      );
    }
  }

  Future<void> _revokeSession(String id) async {
    await _profileDataSource.revokeSession(id);
    await _load();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountConfirmTitle),
        content: Text(l10n.settingsDeleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
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
    final l10n = AppLocalizations.of(context);
    final locale = context.watch<LocaleCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _SectionHeader(title: l10n.settingsAccountSection),
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: l10n.settingsEditProfile,
                      onTap: () => showEditProfileSheet(context, user),
                    ),
                    _SettingsTile(
                      icon: Icons.workspace_premium_rounded,
                      title: l10n.settingsPremium,
                      subtitle: user?.isPremium == true
                          ? l10n.settingsPremiumActive
                          : l10n.settingsPremiumUpgrade,
                      onTap: () => context.push('/premium'),
                    ),
                    if (user?.isPremium == true)
                      _SettingsTile(
                        icon: Icons.cancel_outlined,
                        title: l10n.settingsCancelSubscription,
                        subtitle: l10n.settingsCancelSubscriptionSubtitle,
                        onTap: () => SubscriptionActions.cancelFromContext(context),
                      ),
                    _SettingsTile(
                      icon: Icons.auto_awesome_rounded,
                      title: l10n.settingsAiNotes,
                      onTap: () => context.push('/ai-notes'),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: l10n.settingsLanguageSection),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: l10n.settingsLanguageTile,
                      subtitle: _languageLabel(l10n, locale),
                      onTap: _showLanguagePicker,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: l10n.settingsNotificationsSection),
                    SwitchListTile(
                      title: Text(l10n.settingsStudyReminders),
                      value: _prefs.reminders,
                      onChanged: (v) {
                        setState(() => _prefs = _prefs.copyWith(reminders: v));
                        _saveNotifications();
                      },
                    ),
                    SwitchListTile(
                      title: Text(l10n.settingsStreakAlerts),
                      value: _prefs.streak,
                      onChanged: (v) {
                        setState(() => _prefs = _prefs.copyWith(streak: v));
                        _saveNotifications();
                      },
                    ),
                    SwitchListTile(
                      title: Text(l10n.settingsProductUpdates),
                      value: _prefs.marketing,
                      onChanged: (v) {
                        setState(() => _prefs = _prefs.copyWith(marketing: v));
                        _saveNotifications();
                      },
                    ),
                    const SizedBox(height: 12),
                    _SectionHeader(title: l10n.settingsFocusSection),
                    SwitchListTile(
                      title: Text(l10n.settingsFocusMode),
                      subtitle: Text(l10n.settingsFocusModeSubtitle),
                      value: _focusMode,
                      onChanged: _toggleFocusMode,
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: l10n.settingsActiveDevices),
                    ..._sessions.map(
                      (session) => ListTile(
                        title: Text(session.deviceLabel),
                        subtitle: Text(
                          session.current
                              ? l10n.settingsThisDevice
                              : l10n.settingsOtherDevice,
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
                    _SectionHeader(title: l10n.settingsDangerZone),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: Text(l10n.settingsLogOut),
                      onTap: () =>
                          context.read<AuthBloc>().add(const AuthLogoutRequested()),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                      title: Text(l10n.settingsDeleteAccount, style: const TextStyle(color: AppColors.error)),
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
