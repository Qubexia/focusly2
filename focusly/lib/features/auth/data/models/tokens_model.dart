/// Token pair returned after login/register/refresh.
class TokensModel {
  final String accessToken;
  final String refreshToken;
  final int accessExpiresIn;
  final int refreshExpiresIn;

  const TokensModel({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
  });

  factory TokensModel.fromJson(Map<String, dynamic> json) {
    return TokensModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessExpiresIn: (json['accessExpiresIn'] ?? 900) as int,
      refreshExpiresIn: (json['refreshExpiresIn'] ?? 2592000) as int,
    );
  }
}
