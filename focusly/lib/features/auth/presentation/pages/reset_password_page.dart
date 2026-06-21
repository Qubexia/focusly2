import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _repository = AuthRepository();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _repository.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).authPasswordUpdated)),
      );
      context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = AppLocalizations.of(context).authResetLinkInvalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authResetPasswordAppBar)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.authResetPasswordSubtitle,
                  style: const TextStyle(height: 1.4),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _passwordController,
                  label: l10n.authNewPasswordLabel,
                  hint: l10n.authNewPasswordHint,
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.length < 8) ? l10n.authPasswordMinLength : null,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: _confirmController,
                  label: l10n.authConfirmPasswordLabel,
                  hint: l10n.authConfirmPasswordHint,
                  obscureText: true,
                  validator: (v) => v != _passwordController.text
                      ? l10n.authPasswordsMismatch
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authUpdatePasswordButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
