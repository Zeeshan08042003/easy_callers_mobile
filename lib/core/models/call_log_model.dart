import 'package:easy_callers_mobile/core/utils/enums.dart';

class CallLogModel {
  final String id;
  final String leadId;
  final String employeeId;
  final CallStatus? callStatus;
  final String? callDuration;
  final int callDurationSeconds;
  final CallLeadStatus? leadStatus;
  final String? feedback;
  final DateTime? followUpDate;
  final String? followUpNotes;
  final DateTime createdAt;

  // Joined data
  final String? leadName;
  final String? leadPhone;
  final String? employeeName;

  CallLogModel({
    required this.id,
    required this.leadId,
    required this.employeeId,
    this.callStatus,
    this.callDuration,
    this.callDurationSeconds = 0,
    this.leadStatus,
    this.feedback,
    this.followUpDate,
    this.followUpNotes,
    required this.createdAt,
    this.leadName,
    this.leadPhone,
    this.employeeName,
  });

  bool get hasFollowUp => followUpDate != null;
  bool get isFollowUpDueToday {
    if (followUpDate == null) return false;
    final now = DateTime.now();
    return followUpDate!.year == now.year &&
        followUpDate!.month == now.month &&
        followUpDate!.day == now.day;
  }

  bool get isFollowUpOverdue {
    if (followUpDate == null) return false;
    return followUpDate!.isBefore(DateTime.now());
  }

  factory CallLogModel.fromJson(Map<String, dynamic> json) {
    // Handle joined lead data
    String? lName;
    String? lPhone;
    if (json['leads'] != null && json['leads'] is Map) {
      final lead = json['leads'] as Map<String, dynamic>;
      lName = lead['name'] as String?;
      lPhone = lead['phone'] as String?;
    } else if (json['lead'] != null && json['lead'] is Map) {
      final lead = json['lead'] as Map<String, dynamic>;
      lName = lead['name'] as String?;
      lPhone = lead['phone'] as String?;
    }

    // Handle joined employee data
    String? eName;
    if (json['employees'] != null && json['employees'] is Map) {
      final emp = json['employees'] as Map<String, dynamic>;
      eName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    } else if (json['employee'] != null && json['employee'] is Map) {
      final emp = json['employee'] as Map<String, dynamic>;
      eName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    }

    return CallLogModel(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      employeeId: json['employee_id'] as String,
      callStatus: json['call_status'] != null
          ? CallStatus.fromString(json['call_status'] as String)
          : null,
      callDuration: json['call_duration'] as String?,
      callDurationSeconds: json['call_duration_seconds'] as int? ?? 0,
      leadStatus: json['lead_status'] != null
          ? CallLeadStatus.fromString(json['lead_status'] as String)
          : null,
      feedback: json['feedback'] as String?,
      followUpDate: json['follow_up_date'] != null
          ? DateTime.parse(json['follow_up_date'] as String)
          : null,
      followUpNotes: json['follow_up_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      leadName: lName,
      leadPhone: lPhone,
      employeeName: eName,
    );
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'lead_id': leadId,
      'employee_id': employeeId,
    };
    if (callStatus != null) map['call_status'] = callStatus!.value;
    if (callDuration != null) map['call_duration'] = callDuration;
    if (callDurationSeconds > 0) {
      map['call_duration_seconds'] = callDurationSeconds;
    }
    if (leadStatus != null) map['lead_status'] = leadStatus!.value;
    if (feedback != null) map['feedback'] = feedback;
    if (followUpDate != null) {
      map['follow_up_date'] = followUpDate!.toIso8601String();
    }
    if (followUpNotes != null) map['follow_up_notes'] = followUpNotes;
    return map;
  }

  @override
  String toString() =>
      'CallLogModel(lead: $leadName, status: ${callStatus?.displayName})';
}
