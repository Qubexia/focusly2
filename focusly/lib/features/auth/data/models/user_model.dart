/// Represents the authenticated user returned by the backend.
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final bool emailVerified;
  final String role;
  final String plan;
  final DateTime? premiumUntil;
  final int totalPoints;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.emailVerified,
    required this.role,
    required this.plan,
    this.premiumUntil,
    required this.totalPoints,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      emailVerified: (json['emailVerified'] ?? false) as bool,
      role: (json['role'] ?? 'user') as String,
      plan: (json['plan'] ?? 'free') as String,
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.tryParse(json['premiumUntil'] as String)
          : null,
      totalPoints: (json['totalPoints'] ?? 0) as int,
    );
  }

  bool get isPremium =>
      plan == 'premium' &&
      (premiumUntil == null || premiumUntil!.isAfter(DateTime.now()));
}
