/// Model representing a Project.
/// A project is a container for lead batches and leads.
/// Can be created by either a Super Admin or a Manager.
class ProjectModel {
  final String id;
  final String name;
  final String? subtitle;
  final String? instruction;
  final String? createdBySuperAdminId;
  final String? createdByManagerId;
  final String callerAssignment; // 'all' or 'selected'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined / computed data
  final String? creatorName;
  final String? creatorRole; // 'super_admin' or 'manager'
  final int? batchCount;
  final int? leadCount;
  final int? memberCount;

  ProjectModel({
    required this.id,
    required this.name,
    this.subtitle,
    this.instruction,
    this.createdBySuperAdminId,
    this.createdByManagerId,
    this.callerAssignment = 'all',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.creatorRole,
    this.batchCount,
    this.leadCount,
    this.memberCount,
  });

  /// Whether this project was created by a super admin
  bool get isCreatedBySuperAdmin => createdBySuperAdminId != null;

  /// Whether this project was created by a manager
  bool get isCreatedByManager => createdByManagerId != null;

  /// Whether all callers are assigned or specific selection
  bool get isAllCallers => callerAssignment == 'all';

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Try to extract creator name from joined data
    String? creator;
    String? role;

    if (json['creator_super_admin'] != null && json['creator_super_admin'] is Map) {
      final sa = json['creator_super_admin'] as Map<String, dynamic>;
      creator = '${sa['first_name'] ?? ''} ${sa['last_name'] ?? ''}'.trim();
      role = 'super_admin';
    } else if (json['creator_manager'] != null && json['creator_manager'] is Map) {
      final mgr = json['creator_manager'] as Map<String, dynamic>;
      creator = '${mgr['first_name'] ?? ''} ${mgr['last_name'] ?? ''}'.trim();
      role = 'manager';
    }

    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      instruction: json['instruction'] as String?,
      createdBySuperAdminId: json['created_by_super_admin_id'] as String?,
      createdByManagerId: json['created_by_manager_id'] as String?,
      callerAssignment: json['caller_assignment'] as String? ?? 'all',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creatorName: creator,
      creatorRole: role,
      batchCount: json['batch_count'] as int?,
      leadCount: json['lead_count'] as int?,
      memberCount: json['member_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtitle': subtitle,
      'instruction': instruction,
      'created_by_super_admin_id': createdBySuperAdminId,
      'created_by_manager_id': createdByManagerId,
      'caller_assignment': callerAssignment,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = <String, dynamic>{
      'name': name,
      'caller_assignment': callerAssignment,
      'is_active': isActive,
    };
    if (subtitle != null) map['subtitle'] = subtitle;
    if (instruction != null) map['instruction'] = instruction;
    if (createdBySuperAdminId != null) {
      map['created_by_super_admin_id'] = createdBySuperAdminId;
    }
    if (createdByManagerId != null) {
      map['created_by_manager_id'] = createdByManagerId;
    }
    return map;
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? subtitle,
    String? instruction,
    String? createdBySuperAdminId,
    String? createdByManagerId,
    String? callerAssignment,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? batchCount,
    int? leadCount,
    int? memberCount,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      instruction: instruction ?? this.instruction,
      createdBySuperAdminId: createdBySuperAdminId ?? this.createdBySuperAdminId,
      createdByManagerId: createdByManagerId ?? this.createdByManagerId,
      callerAssignment: callerAssignment ?? this.callerAssignment,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      batchCount: batchCount ?? this.batchCount,
      leadCount: leadCount ?? this.leadCount,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  String toString() => 'ProjectModel($name, active: $isActive)';
}
