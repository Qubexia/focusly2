import 'package:go_router/go_router.dart';

import '../../features/ai/data/models/ai_artifact_model.dart';
import '../../features/ai/presentation/pages/ai_artifact_viewer_page.dart';
import '../../features/ai/presentation/pages/ai_notes_hub_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/subscription/presentation/pages/paywall_page.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/pomodoro/presentation/pages/pomodoro_history_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/subjects/presentation/pages/subject_detail_page.dart';
import '../../features/subjects/presentation/pages/subjects_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => ResetPasswordPage(
        token: state.uri.queryParameters['token'] ?? '',
      ),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => VerifyEmailPage(
        token: state.uri.queryParameters['token'] ?? '',
      ),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => PaywallPage(
        paymentResult: state.uri.queryParameters['paid'],
      ),
    ),
    GoRoute(
      path: '/ai-notes',
      builder: (context, state) => const AiNotesHubPage(),
    ),
    GoRoute(
      path: '/ai-notes/viewer',
      builder: (context, state) {
        final artifacts = state.extra as List<AiArtifactModel>? ?? const [];
        return AiArtifactViewerPage(artifacts: artifacts);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '');
        return MainShell(initialIndex: tab == null ? 0 : tab.clamp(0, 4));
      },
    ),
    GoRoute(
      path: '/pomodoro/history',
      builder: (context, state) => const PomodoroHistoryPage(),
    ),
    GoRoute(
      path: '/subjects',
      builder: (context, state) => const SubjectsPage(),
    ),
    GoRoute(
      path: '/subjects/:id',
      builder: (context, state) =>
          SubjectDetailPage(subjectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/profile/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
