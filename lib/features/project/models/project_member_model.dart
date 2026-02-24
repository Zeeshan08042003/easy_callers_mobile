/// Model representing a Project Member (manager linked to a project).
/// Handles the invitation flow: pending → accepted/declined.
class ProjectMemberModel {
  final String id;
  final String projectId;
  final String managerId;
  final String role; // 'owner' or 'member'
  final String status; // 'pending', 'accepted', 'declined'
  final bool visibleToSuperAdmin;
  final bool canUpload; // Whether SA granted upload permission
  final String? invitedBySuperAdminId;
  final String? invitedByManagerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? managerName;
  final String? managerEmail;
  final bool managerIsActive;
  final String? projectName;
  final String? invitedByName;

  ProjectMemberModel({
    required this.id,
    required this.projectId,
    required this.managerId,
    this.role = 'member',
    this.status = 'pending',
    this.visibleToSuperAdmin = false,
    this.canUpload = false,
    this.invitedBySuperAdminId,
    this.invitedByManagerId,
    required this.createdAt,
    required this.updatedAt,
    this.managerName,
    this.managerEmail,
    this.managerIsActive = true,
    this.projectName,
    this.invitedByName,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isOwner => role == 'owner';

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    // Extract joined manager data
    String? mgrName;
    String? mgrEmail;
    bool mgrIsActive;
    if (json['manager'] != null && json['manager'] is Map) {
      final mgr = json['manager'] as Map<String, dynamic>;
      mgrName = '${mgr['first_name'] ?? ''} ${mgr['last_name'] ?? ''}'.trim();
      mgrEmail = mgr['email'] as String?;
      mgrIsActive = mgr['is_active'] as bool? ?? true;
    } else {
      mgrIsActive = true;
    }

    // Extract joined project data
    String? projName;
    if (json['project'] != null && json['project'] is Map) {
      final proj = json['project'] as Map<String, dynamic>;
      projName = proj['name'] as String?;
    }

    // Extract invited by name
    String? inviterName;
    if (json['inviter_super_admin'] != null && json['inviter_super_admin'] is Map) {
      final sa = json['inviter_super_admin'] as Map<String, dynamic>;
      inviterName = '${sa['first_name'] ?? ''} ${sa['last_name'] ?? ''}'.trim();
    } else if (json['inviter_manager'] != null && json['inviter_manager'] is Map) {
      final mgr = json['inviter_manager'] as Map<String, dynamic>;
      inviterName = '${mgr['first_name'] ?? ''} ${mgr['last_name'] ?? ''}'.trim();
    }

    return ProjectMemberModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      managerId: json['manager_id'] as String,
      role: json['role'] as String? ?? 'member',
      status: json['status'] as String? ?? 'pending',
      visibleToSuperAdmin: json['visible_to_super_admin'] as bool? ?? false,
      canUpload: json['can_upload'] as bool? ?? false,
      invitedBySuperAdminId: json['invited_by_super_admin_id'] as String?,
      invitedByManagerId: json['invited_by_manager_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      managerName: mgrName,
      managerEmail: mgrEmail,
      managerIsActive: mgrIsActive,
      projectName: projName,
      invitedByName: inviterName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'manager_id': managerId,
      'role': role,
      'status': status,
      'visible_to_super_admin': visibleToSuperAdmin,
      'can_upload': canUpload,
      'invited_by_super_admin_id': invitedBySuperAdminId,
      'invited_by_manager_id': invitedByManagerId,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'project_id': projectId,
      'manager_id': managerId,
      'role': role,
      'status': status,
      'visible_to_super_admin': visibleToSuperAdmin,
      'can_upload': canUpload,
    };
    if (invitedBySuperAdminId != null) {
      map['invited_by_super_admin_id'] = invitedBySuperAdminId;
    }
    if (invitedByManagerId != null) {
      map['invited_by_manager_id'] = invitedByManagerId;
    }
    return map;
  }

  ProjectMemberModel copyWith({
    String? id,
    String? projectId,
    String? managerId,
    String? role,
    String? status,
    bool? visibleToSuperAdmin,
    bool? canUpload,
    String? invitedBySuperAdminId,
    String? invitedByManagerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectMemberModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      managerId: managerId ?? this.managerId,
      role: role ?? this.role,
      status: status ?? this.status,
      visibleToSuperAdmin: visibleToSuperAdmin ?? this.visibleToSuperAdmin,
      canUpload: canUpload ?? this.canUpload,
      invitedBySuperAdminId: invitedBySuperAdminId ?? this.invitedBySuperAdminId,
      invitedByManagerId: invitedByManagerId ?? this.invitedByManagerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ProjectMember(project: $projectId, manager: $managerId, status: $status)';
}
