class DailyReportModel {
  final String id;
  final String employeeId;
  final DateTime reportDate;
  final int totalCalls;
  final int connectedCalls;
  final int notConnectedCalls;
  final int interestedLeads;
  final int notInterestedLeads;
  final int followUpsScheduled;
  final int avgCallDurationSeconds;
  final int totalCallDurationSeconds;
  final DateTime createdAt;

  // Joined data
  final String? employeeName;

  DailyReportModel({
    required this.id,
    required this.employeeId,
    required this.reportDate,
    this.totalCalls = 0,
    this.connectedCalls = 0,
    this.notConnectedCalls = 0,
    this.interestedLeads = 0,
    this.notInterestedLeads = 0,
    this.followUpsScheduled = 0,
    this.avgCallDurationSeconds = 0,
    this.totalCallDurationSeconds = 0,
    required this.createdAt,
    this.employeeName,
  });

  /// Connection rate as a percentage
  double get connectionRate =>
      totalCalls > 0 ? (connectedCalls / totalCalls) * 100 : 0;

  /// Average call duration formatted
  String get avgCallDurationFormatted {
    final minutes = avgCallDurationSeconds ~/ 60;
    final seconds = avgCallDurationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Total call duration formatted
  String get totalCallDurationFormatted {
    final hours = totalCallDurationSeconds ~/ 3600;
    final minutes = (totalCallDurationSeconds % 3600) ~/ 60;
    final seconds = totalCallDurationSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    String? eName;
    if (json['employees'] != null && json['employees'] is Map) {
      final emp = json['employees'] as Map<String, dynamic>;
      eName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    } else if (json['employee'] != null && json['employee'] is Map) {
      final emp = json['employee'] as Map<String, dynamic>;
      eName = '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    }

    return DailyReportModel(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      reportDate: DateTime.parse(json['report_date'] as String),
      totalCalls: json['total_calls'] as int? ?? 0,
      connectedCalls: json['connected_calls'] as int? ?? 0,
      notConnectedCalls: json['not_connected_calls'] as int? ?? 0,
      interestedLeads: json['interested_leads'] as int? ?? 0,
      notInterestedLeads: json['not_interested_leads'] as int? ?? 0,
      followUpsScheduled: json['follow_ups_scheduled'] as int? ?? 0,
      avgCallDurationSeconds: json['avg_call_duration_seconds'] as int? ?? 0,
      totalCallDurationSeconds:
          json['total_call_duration_seconds'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      employeeName: eName,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'employee_id': employeeId,
      'report_date': reportDate.toIso8601String().split('T')[0],
      'total_calls': totalCalls,
      'connected_calls': connectedCalls,
      'not_connected_calls': notConnectedCalls,
      'interested_leads': interestedLeads,
      'not_interested_leads': notInterestedLeads,
      'follow_ups_scheduled': followUpsScheduled,
      'avg_call_duration_seconds': avgCallDurationSeconds,
      'total_call_duration_seconds': totalCallDurationSeconds,
    };
  }

  @override
  String toString() =>
      'DailyReportModel($reportDate, $totalCalls calls, ${connectionRate.toStringAsFixed(1)}% connected)';
}
