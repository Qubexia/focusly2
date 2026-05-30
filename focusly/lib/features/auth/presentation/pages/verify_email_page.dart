import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository_impl.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.token});

  final String token;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _repository = AuthRepository();
  bool _isLoading = true;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    try {
      await _repository.verifyEmail(token: widget.token);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _success = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Verification link is invalid or expired.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_success) ...[
                const Icon(Icons.verified_rounded, size: 72, color: AppColors.secondary),
                const SizedBox(height: 16),
                const Text(
                  'Email verified successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Continue to login'),
                ),
              ] else ...[
                const Icon(Icons.error_outline_rounded, size: 72, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error ?? 'Verification failed', textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
