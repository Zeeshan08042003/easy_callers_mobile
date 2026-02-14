class SystemSettingsModel {
  final String id;
  final String companyName;
  final String? supportEmail;
  final String? supportPhone;
  final int maxLeadsPerEmployee;
  final int dailyCallTarget;
  final bool maintenanceMode;
  final DateTime updatedAt;

  SystemSettingsModel({
    required this.id,
    required this.companyName,
    this.supportEmail,
    this.supportPhone,
    this.maxLeadsPerEmployee = 100,
    this.dailyCallTarget = 50,
    this.maintenanceMode = false,
    required this.updatedAt,
  });

  factory SystemSettingsModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingsModel(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      supportEmail: json['support_email'] as String?,
      supportPhone: json['support_phone'] as String?,
      maxLeadsPerEmployee: json['max_leads_per_employee'] as int? ?? 100,
      dailyCallTarget: json['daily_call_target'] as int? ?? 50,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_name': companyName,
      'support_email': supportEmail,
      'support_phone': supportPhone,
      'max_leads_per_employee': maxLeadsPerEmployee,
      'daily_call_target': dailyCallTarget,
      'maintenance_mode': maintenanceMode,
    };
  }
}
