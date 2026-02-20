class LeadStatusModel {
  final String id;
  final String value;
  final String displayName;
  final String leadStatusMapping;
  final String? managerId;
  final bool isActive;

  LeadStatusModel({
    required this.id,
    required this.value,
    required this.displayName,
    required this.leadStatusMapping,
    this.managerId,
    this.isActive = true,
  });

  factory LeadStatusModel.fromJson(Map<String, dynamic> json) {
    return LeadStatusModel(
      id: json['id'] as String,
      value: json['value'] as String,
      displayName: json['display_name'] as String,
      leadStatusMapping: json['lead_status_mapping'] as String? ?? 'follow_up',
      managerId: json['manager_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'display_name': displayName,
      'lead_status_mapping': leadStatusMapping,
      'manager_id': managerId,
      'is_active': isActive,
    };
  }
}
