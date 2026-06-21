import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/localization/app_l10n.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_event_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthRefreshUser>(_onRefreshUser);
    on<AuthUserSynced>(_onUserSynced);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthGoogleLoginRequested>(_onGoogleLogin);
    on<AuthForgotPasswordRequested>(_onForgotPassword);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdateRequested>(_onProfileUpdate);
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.tryAutoLogin();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onRefreshUser(
    AuthRefreshUser event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      await _authRepository.refreshSessionTokens();
      final user = await _authRepository.fetchCurrentUser();
      emit(AuthAuthenticated(user: user));
    } catch (_) {
      // Keep the current session if refresh fails.
    }
  }

  void _onUserSynced(AuthUserSynced event, Emitter<AuthState> emit) {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;
    if (currentState.user.id != event.user.id) return;
    emit(AuthAuthenticated(user: event.user));
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: response.user));
    } on DioException catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: response.user));
    } on DioException catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onGoogleLogin(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        emit(AuthError(message: AppL10n.current.authGoogleTokenFailed));
        return;
      }

      final response = await _authRepository.googleLogin(idToken: idToken);
      emit(AuthAuthenticated(user: response.user));
    } on DioException catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError(message: AppL10n.current.authGoogleSignInFailed));
    }
  }

  Future<void> _onForgotPassword(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.forgotPassword(email: event.email);
      emit(const AuthForgotPasswordSuccess());
    } on DioException catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onProfileUpdate(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    try {
      final updatedUser = await _authRepository.updateProfile(
        name: event.name,
        avatarPath: event.avatarPath,
      );
      emit(AuthAuthenticated(user: updatedUser));
    } on DioException catch (e) {
      emit(AuthError(message: _extractErrorMessage(e)));
      emit(currentState);
    } catch (e) {
      emit(AuthError(message: e.toString()));
      emit(currentState);
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ?? AppL10n.current.commonError;
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppL10n.current.authServerUnreachable;
    }
    return AppL10n.current.authGenericRetry;
  }
}
