/// User roles in the system
enum UserRole {
  superAdmin('super_admin'),
  manager('manager'),
  employee('employee');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.employee,
    );
  }
}

/// Lead status throughout its lifecycle
enum LeadStatus {
  newLead('new'),
  assigned('assigned'),
  connected('connected'),
  notConnected('not_connected'),
  interested('interested'),
  notInterested('not_interested'),
  followUp('follow_up'),
  converted('converted'),
  closed('closed');

  final String value;
  const LeadStatus(this.value);

  String get displayName {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.assigned:
        return 'Assigned';
      case LeadStatus.connected:
        return 'Connected';
      case LeadStatus.notConnected:
        return 'Not Connected';
      case LeadStatus.interested:
        return 'Interested';
      case LeadStatus.notInterested:
        return 'Not Interested';
      case LeadStatus.followUp:
        return 'Follow Up';
      case LeadStatus.converted:
        return 'Converted';
      case LeadStatus.closed:
        return 'Closed';
    }
  }

  static LeadStatus fromString(String value) {
    return LeadStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LeadStatus.newLead,
    );
  }
}

/// Call outcome status
enum CallStatus {
  completed('Completed'),
  declinedOrFailed('Declined or Failed'),
  busy('Busy'),
  switchedOff('Switched Off'),
  wrongNumber('Wrong Number'),
  notReachable('Not Reachable');

  final String value;
  const CallStatus(this.value);

  String get displayName {
    switch (this) {
      case CallStatus.completed:
        return 'Completed';
      case CallStatus.declinedOrFailed:
        return 'Declined or Failed';
      case CallStatus.busy:
        return 'Busy';
      case CallStatus.switchedOff:
        return 'Switched Off';
      case CallStatus.wrongNumber:
        return 'Wrong Number';
      case CallStatus.notReachable:
        return 'Not Reachable';
    }
  }

  static CallStatus fromString(String value) {
    // Exact match
    for (var status in CallStatus.values) {
      if (status.value.toLowerCase() == value.toLowerCase()) {
        return status;
      }
    }
    
    // Fallback mappings
    final lower = value.toLowerCase();
    if (lower.contains('completed') || lower.contains('connected')) {
      return CallStatus.completed;
    }
    if (lower.contains('declined') || lower.contains('failed') || lower.contains('no_answer') || lower.contains('not_connected')) {
      return CallStatus.declinedOrFailed;
    }

    return CallStatus.declinedOrFailed;
  }
}

/// Lead interest status after a call
enum CallLeadStatus {
  interested('interested'),
  notInterested('not_interested'),
  followUp('follow_up'),
  callback('callback'),
  visiting('visiting'),
  closed('closed');

  final String value;
  const CallLeadStatus(this.value);

  String get displayName {
    switch (this) {
      case CallLeadStatus.interested:
        return 'Interested';
      case CallLeadStatus.notInterested:
        return 'Not Interested';
      case CallLeadStatus.followUp:
        return 'Follow Up';
      case CallLeadStatus.callback:
        return 'Callback';
      case CallLeadStatus.visiting:
        return 'Visiting';
      case CallLeadStatus.closed:
        return 'Closed';
    }
  }

  static CallLeadStatus fromString(String value) {
    return CallLeadStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CallLeadStatus.followUp,
    );
  }
}

/// Notification types
enum NotificationType {
  followUpReminder('follow_up_reminder'),
  leadAssigned('lead_assigned'),
  reportReady('report_ready'),
  otp('otp'),
  general('general'),
  superAdminChange('super_admin_change'),
  leadReassigned('lead_reassigned'),
  employeeDeactivated('employee_deactivated');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }
}
