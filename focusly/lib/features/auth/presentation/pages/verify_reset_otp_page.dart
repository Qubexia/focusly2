import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../widgets/auth_text_field.dart';

class VerifyResetOtpPage extends StatefulWidget {
  const VerifyResetOtpPage({super.key, required this.email});

  final String email;

  @override
  State<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends State<VerifyResetOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _repository = AuthRepository();

  var _isVerifying = false;
  var _isResending = false;
  String? _error;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
        return;
      }
      setState(() => _resendCooldown -= 1);
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final resetToken = await _repository.verifyResetOtp(
        email: widget.email,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      if (resetToken.isEmpty) {
        setState(() {
          _isVerifying = false;
          _error = AppLocalizations.of(context).authOtpInvalid;
        });
        return;
      }
      context.pushReplacement(
        '/reset-password?token=${Uri.encodeQueryComponent(resetToken)}',
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = _extractMessage(e) ??
            AppLocalizations.of(context).authOtpInvalid;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = AppLocalizations.of(context).authOtpInvalid;
      });
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _error = null;
    });

    try {
      await _repository.forgotPassword(email: widget.email);
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).authOtpResent),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).authOtpResendError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String?;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.email.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.authOtpAppBar)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.authOtpInvalid, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: Text(l10n.authSendResetOtpButton),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authOtpAppBar)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.authOtpSubtitle(widget.email),
                  style: TextStyle(
                    height: 1.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  controller: _otpController,
                  label: l10n.authOtpLabel,
                  hint: l10n.authOtpHint,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    final otp = value?.trim() ?? '';
                    if (otp.length != 6) return l10n.authOtpInvalidLength;
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isVerifying ? null : _verify,
                  child: _isVerifying
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authVerifyOtpButton),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      (_resendCooldown > 0 || _isResending) ? null : _resend,
                  child: Text(
                    _resendCooldown > 0
                        ? l10n.authResendOtpIn(_resendCooldown)
                        : l10n.authResendOtpButton,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
