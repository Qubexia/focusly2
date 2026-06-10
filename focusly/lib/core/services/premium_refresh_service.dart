import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event_state.dart';

/// Keeps premium status in sync after payment webhooks land on the server.
class PremiumRefreshService {
  PremiumRefreshService._();

  static final PremiumRefreshService instance = PremiumRefreshService._();

  final AuthRepository _authRepository = AuthRepository();

  /// Re-issues JWT access token from DB (updates embedded plan claim).
  Future<bool> refreshSessionTokens() => _authRepository.refreshSessionTokens();

  Future<bool> syncUserProfile(AuthBloc authBloc) async {
    try {
      await _authRepository.refreshSessionTokens();
      final user = await _authRepository.fetchCurrentUser();
      authBloc.add(AuthUserSynced(user));
      return user.isPremium;
    } catch (_) {
      return false;
    }
  }

  Future<bool> refreshUntilPremium(
    AuthBloc authBloc, {
    int attempts = 8,
    Duration interval = const Duration(milliseconds: 750),
  }) async {
    for (var i = 0; i < attempts; i++) {
      try {
        await _authRepository.refreshSessionTokens();
        final user = await _authRepository.fetchCurrentUser();
        authBloc.add(AuthUserSynced(user));
        if (user.isPremium) return true;
      } catch (_) {}

      if (i < attempts - 1) {
        await Future.delayed(interval);
      }
    }

    final state = authBloc.state;
    return state is AuthAuthenticated && state.user.isPremium;
  }

  Future<void> refreshOnce(AuthBloc authBloc) async {
    try {
      await _authRepository.refreshSessionTokens();
      final user = await _authRepository.fetchCurrentUser();
      authBloc.add(AuthUserSynced(user));
    } catch (_) {
      authBloc.add(const AuthRefreshUser());
    }
  }

  /// After cancel/upgrade — refresh JWT claims and user profile from the server.
  Future<void> syncAfterSubscriptionChange(AuthBloc authBloc) async {
    await refreshOnce(authBloc);
  }
}

bool premiumStatusChanged(AuthState previous, AuthState current) {
  final wasPremium =
      previous is AuthAuthenticated && previous.user.isPremium;
  final isPremium = current is AuthAuthenticated && current.user.isPremium;
  return wasPremium != isPremium;
}

bool isPremiumRequiredError(Object? responseData) {
  if (responseData is! Map<String, dynamic>) return false;
  final code = responseData['code'] as String?;
  final message = (responseData['message'] as String?)?.toLowerCase() ?? '';
  return code == 'PREMIUM_REQUIRED' || message.contains('upgrade to premium');
}
