class PlatformConfigData {
  const PlatformConfigData({
    required this.premiumGatingEnabled,
    required this.freeSubjectLimit,
    required this.aiHourlyLimit,
    required this.aiMonthlyLimit,
    required this.maintenanceMode,
    this.maintenanceMessage,
  });

  final bool premiumGatingEnabled;
  final int freeSubjectLimit;
  final int aiHourlyLimit;
  final int aiMonthlyLimit;
  final bool maintenanceMode;
  final String? maintenanceMessage;

  static const defaults = PlatformConfigData(
    premiumGatingEnabled: false,
    freeSubjectLimit: 3,
    aiHourlyLimit: 5,
    aiMonthlyLimit: 30,
    maintenanceMode: false,
  );

  factory PlatformConfigData.fromJson(Map<String, dynamic> json) {
    return PlatformConfigData(
      premiumGatingEnabled: json['premiumGatingEnabled'] as bool? ?? false,
      freeSubjectLimit: (json['freeSubjectLimit'] as num?)?.toInt() ?? 3,
      aiHourlyLimit: (json['aiHourlyLimit'] as num?)?.toInt() ?? 5,
      aiMonthlyLimit: (json['aiMonthlyLimit'] as num?)?.toInt() ?? 30,
      maintenanceMode: json['maintenanceMode'] as bool? ?? false,
      maintenanceMessage: json['maintenanceMessage'] as String?,
    );
  }
}

/// Cached platform settings from GET /v1/config (admin-controlled).
class PlatformConfig {
  PlatformConfig._();

  static PlatformConfigData _data = PlatformConfigData.defaults;

  static PlatformConfigData get current => _data;

  static void update(PlatformConfigData data) {
    _data = data;
  }

  static void reset() {
    _data = PlatformConfigData.defaults;
  }
}
