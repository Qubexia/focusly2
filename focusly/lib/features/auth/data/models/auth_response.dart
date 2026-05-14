import 'tokens_model.dart';
import 'user_model.dart';

/// Combined auth response from login / register / google login.
class AuthResponse {
  final UserModel user;
  final TokensModel tokens;

  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokensModel.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}
