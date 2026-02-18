import 'package:easy_callers_mobile/core/utils/enums.dart';

class NotificationModel {
  final String id;
  // Role-specific IDs (exactly one will be non-null)
  final String? superAdminId;
  final String? managerId;
  final String? employeeId;
  
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.superAdminId,
    this.managerId,
    this.employeeId,
    required this.title,
    required this.body,
    this.type = NotificationType.general,
    this.isRead = false,
    this.metadata = const {},
    required this.createdAt,
  });

  /// Helper to get the active recipient ID regardless of role
  String? get recipientId => superAdminId ?? managerId ?? employeeId;

  /// Helper to get the role of the recipient
  UserRole get recipientRole {
    if (superAdminId != null) return UserRole.superAdmin;
    if (managerId != null) return UserRole.manager;
    return UserRole.employee;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      superAdminId: json['super_admin_id'] as String?,
      managerId: json['manager_id'] as String?,
      employeeId: json['employee_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.fromString(json['type'] as String? ?? 'general'),
      isRead: json['is_read'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (superAdminId != null) 'super_admin_id': superAdminId,
      if (managerId != null) 'manager_id': managerId,
      if (employeeId != null) 'employee_id': employeeId,
      'title': title,
      'body': body,
      'type': type.value,
      'is_read': isRead,
      'metadata': metadata,
    };
  }

  @override
  String toString() => 'NotificationModel($title, to: $recipientRole)';
}
