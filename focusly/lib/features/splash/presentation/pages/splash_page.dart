import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Let the animation play for a bit
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
    } else {
      // Try auto-login
      context.read<AuthBloc>().add(const AuthCheckStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF0A1A33),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthUnauthenticated || state is AuthError) {
            context.go('/login');
          }
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A1A33), // deep navy
                  Color(0xFF0B2A52),
                  Color(0xFF0A4FA0), // brand blue
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // ── Decorative ambient glow orbs ──
                _GlowOrb(
                  top: -130,
                  right: -110,
                  size: 340,
                  color: AppColors.primary.withValues(alpha: 0.55),
                ),
                _GlowOrb(
                  bottom: -150,
                  left: -120,
                  size: 320,
                  color: AppColors.primaryLight.withValues(alpha: 0.40),
                  delay: 200.ms,
                ),

                // ── Center brand content ──
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LogoBadge(),

                      const SizedBox(height: 36),

                      // App name with a soft gradient sheen
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFB8DCFF)],
                        ).createShader(bounds),
                        child: const Text(
                          'Zakerly',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            height: 1.0,
                          ),
                        ),
                      )
                          .animate(delay: 350.ms)
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 14),

                      // Tagline
                      Text(
                        'Study smarter. Stay focused.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ).animate(delay: 600.ms).fadeIn(duration: 600.ms),
                    ],
                  ),
                ),

                // ── Loading indicator pinned near the bottom ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 64,
                  child: Center(
                    child: const _LoadingDots(color: Colors.white)
                        .animate(delay: 900.ms)
                        .fadeIn(duration: 500.ms),
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

// ─────────────────────────── Logo badge ───────────────────────────
/// The brand logo presented inside an elevated squircle card with a
/// pulsing glow halo behind it.
class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow halo
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.55),
                  AppColors.primaryLight.withValues(alpha: 0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.82, 0.82),
                end: const Offset(1.12, 1.12),
                duration: 2200.ms,
                curve: Curves.easeInOut,
              )
              .fade(begin: 0.55, end: 1.0, duration: 2200.ms),

          // Logo card
          Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 40,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const AppLogo(width: 88, height: 88),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                duration: 750.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────── Glow orb ───────────────────────────
/// A soft, heavily-blurred circle used to add depth to the background.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
    this.delay = Duration.zero,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ).animate(delay: delay).fadeIn(duration: 1200.ms),
    );
  }
}

// ─────────────────────────── Loading dots ───────────────────────────
/// A minimal three-dot loader that pulses in sequence.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots({required this.color});

  final Color color;

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Phase-shifted wave so the dots pulse one after another.
            final phase = (_controller.value - i * 0.18) % 1.0;
            final wave = math.sin(phase * math.pi).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * wave;
            final opacity = 0.35 + 0.65 * wave;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
