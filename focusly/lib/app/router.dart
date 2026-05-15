import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/main_shell.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
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
      path: '/home',
      builder: (context, state) => const MainShell(),
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
  ],
);
