class SubscriptionModel {
  const SubscriptionModel({
    required this.status,
    this.provider,
    this.currentPeriodEnd,
  });

  final String status;
  final String? provider;
  final DateTime? currentPeriodEnd;

  bool get isActive =>
      status == 'active' || status == 'trialing';

  factory SubscriptionModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SubscriptionModel(status: 'none');
    }
    return SubscriptionModel(
      status: (json['status'] as String?) ?? 'none',
      provider: json['provider'] as String?,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.tryParse(json['currentPeriodEnd'] as String)
          : null,
    );
  }
}
