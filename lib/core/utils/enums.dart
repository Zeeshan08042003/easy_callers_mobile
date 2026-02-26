/// User roles in the system
enum UserRole {
  superAdmin('super_admin'),
  manager('manager'),
  employee('employee'),
  agency('agency');

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
  followUp('follow_up'),
  notInterested('not_interested'),
  visiting('visiting'),
  visitCompleted('visit_completed'),
  converted('converted'),
  drop('drop');

  final String value;
  const LeadStatus(this.value);

  String get displayName {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.assigned:
        return 'Assigned';
      case LeadStatus.followUp:
        return 'Follow Up';
      case LeadStatus.notInterested:
        return 'Not Interested';
      case LeadStatus.visiting:
        return 'Visiting';
      case LeadStatus.visitCompleted:
        return 'Visit Completed';
      case LeadStatus.converted:
        return 'Converted';
      case LeadStatus.drop:
        return 'Drop';
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
  followUp('follow_up'),
  notInterested('not_interested'),
  visiting('visiting'),
  visitCompleted('visit_completed'),
  converted('converted'),
  drop('drop');

  final String value;
  const CallLeadStatus(this.value);

  String get displayName {
    switch (this) {
      case CallLeadStatus.followUp:
        return 'Follow Up';
      case CallLeadStatus.notInterested:
        return 'Not Interested';
      case CallLeadStatus.visiting:
        return 'Visiting';
      case CallLeadStatus.visitCompleted:
        return 'Visit Completed';
      case CallLeadStatus.converted:
        return 'Converted';
      case CallLeadStatus.drop:
        return 'Drop';
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
  employeeDeactivated('employee_deactivated'),
  projectInvitation('project_invitation'),
  projectInvitationAccepted('project_invitation_accepted'),
  projectInvitationDeclined('project_invitation_declined');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

/// Role of a manager within a project
enum ProjectMemberRole {
  owner('owner'),
  member('member');

  final String value;
  const ProjectMemberRole(this.value);

  String get displayName {
    switch (this) {
      case ProjectMemberRole.owner:
        return 'Owner';
      case ProjectMemberRole.member:
        return 'Member';
    }
  }

  static ProjectMemberRole fromString(String value) {
    return ProjectMemberRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProjectMemberRole.member,
    );
  }
}

/// Status of a project membership/invitation
enum ProjectMemberStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined');

  final String value;
  const ProjectMemberStatus(this.value);

  String get displayName {
    switch (this) {
      case ProjectMemberStatus.pending:
        return 'Pending';
      case ProjectMemberStatus.accepted:
        return 'Accepted';
      case ProjectMemberStatus.declined:
        return 'Declined';
    }
  }

  static ProjectMemberStatus fromString(String value) {
    return ProjectMemberStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProjectMemberStatus.pending,
    );
  }
}
