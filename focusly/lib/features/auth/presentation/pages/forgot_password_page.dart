import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:zakerly/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event_state.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthForgotPasswordRequested(email: _emailController.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthForgotPasswordSuccess) {
          setState(() => _emailSent = true);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Decorative Background Glow
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(
                    alpha: isDark ? 0.2 : 0.15,
                  ),
                ),
              ).animate().fadeIn(duration: 1000.ms).scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 1000.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const SizedBox(height: 16),

                  // Back button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.cardDark
                          : AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (!_emailSent) ...[
                    // Header
                    Text(
                      l10n.authForgotPasswordTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 12),

                    Text(
                      l10n.authForgotPasswordSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 40),

                    AuthTextField(
                      controller: _emailController,
                      label: l10n.authEmailLabel,
                      hint: l10n.authEmailHint,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.authEmailRequired;
                        }
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return l10n.authEmailInvalid;
                        }
                        return null;
                      },
                    ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: 32),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(l10n.authSendResetLinkButton),
                          ),
                        );
                      },
                    ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  ] else ...[
                    // Success state
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),

                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.secondary
                                  .withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              size: 48,
                              color: AppColors.secondary,
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.0, 1.0),
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(duration: 400.ms),

                          const SizedBox(height: 32),

                          Text(
                            l10n.authCheckEmailTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                          const SizedBox(height: 12),

                          Text(
                            l10n.authResetLinkSentTo(_emailController.text),
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                      height: 1.5,
                                    ),
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                          const SizedBox(height: 40),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => context.go('/login'),
                              child: Text(l10n.authBackToSignInButton),
                            ),
                          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
}
}
