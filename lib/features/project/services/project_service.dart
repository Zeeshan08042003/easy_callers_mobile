import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/project/models/project_member_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';

/// Service for all project-related database operations.
/// Handles CRUD for projects, membership management, and invitation flow.
class ProjectService extends GetxService {
  final SupabaseService _supabase = Get.find<SupabaseService>();

  // ============================================
  // PROJECT CRUD
  // ============================================

  /// Create a new project (by Super Admin)
  Future<ProjectModel?> createProjectAsSuperAdmin({
    required String name,
    String? subtitle,
    String? instruction,
    required String superAdminId,
    String callerAssignment = 'all',
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'created_by_super_admin_id': superAdminId,
        'caller_assignment': callerAssignment,
        'is_active': true,
      };
      if (subtitle != null && subtitle.isNotEmpty) {
        data['subtitle'] = subtitle;
      }
      if (instruction != null && instruction.isNotEmpty) {
        data['instruction'] = instruction;
      }

      final response = await _supabase.projectsTable
          .insert(data)
          .select()
          .single();

      return ProjectModel.fromJson(response);
    } catch (e) {
      print('Error creating project as super admin: $e');
      rethrow;
    }
  }

  /// Create a new project (by Manager)
  Future<ProjectModel?> createProjectAsManager({
    required String name,
    String? subtitle,
    String? instruction,
    required String managerId,
    bool visibleToSuperAdmin = false,
    String callerAssignment = 'all',
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'created_by_manager_id': managerId,
        'caller_assignment': callerAssignment,
        'is_active': true,
      };
      if (subtitle != null && subtitle.isNotEmpty) {
        data['subtitle'] = subtitle;
      }
      if (instruction != null && instruction.isNotEmpty) {
        data['instruction'] = instruction;
      }

      final response = await _supabase.projectsTable
          .insert(data)
          .select()
          .single();

      final project = ProjectModel.fromJson(response);

      // Also add the manager as 'owner' member with accepted status
      await _supabase.projectMembersTable.insert({
        'project_id': project.id,
        'manager_id': managerId,
        'role': 'owner',
        'status': 'accepted',
        'visible_to_super_admin': visibleToSuperAdmin,
      });

      return project;
    } catch (e) {
      print('Error creating project as manager: $e');
      rethrow;
    }
  }

  /// Get all projects for a Super Admin
  /// Shows: projects they created + projects shared by managers
  Future<List<ProjectModel>> getProjectsForSuperAdmin(String superAdminId) async {
    try {
      final response = await _supabase.projectsTable
          .select('''
            *,
            creator_super_admin:created_by_super_admin_id(first_name, last_name),
            creator_manager:created_by_manager_id(first_name, last_name)
          ''')
          .order('created_at', ascending: false);

      final projects = (response as List)
          .map((json) => ProjectModel.fromJson(json))
          .toList();

      return await _enrichWithCounts(projects);
    } catch (e) {
      print('Error fetching projects for super admin: $e');
      return [];
    }
  }

  /// Get all projects for a Manager
  /// Shows: projects they created + projects they are members of
  Future<List<ProjectModel>> getProjectsForManager(String managerId) async {
    try {
      // Get projects created by this manager
      final ownProjects = await _supabase.projectsTable
          .select('''
            *,
            creator_super_admin:created_by_super_admin_id(first_name, last_name),
            creator_manager:created_by_manager_id(first_name, last_name)
          ''')
          .eq('created_by_manager_id', managerId)
          .order('created_at', ascending: false);

      // Get projects where this manager is a member (accepted)
      final membershipData = await _supabase.projectMembersTable
          .select('project_id')
          .eq('manager_id', managerId)
          .eq('status', 'accepted')
          .neq('role', 'owner'); // Exclude owner memberships (already in ownProjects)

      final memberProjectIds = (membershipData as List)
          .map((m) => m['project_id'] as String)
          .toList();

      List<ProjectModel> memberProjects = [];
      if (memberProjectIds.isNotEmpty) {
        final memberProjectsData = await _supabase.projectsTable
            .select('''
              *,
              creator_super_admin:created_by_super_admin_id(first_name, last_name),
              creator_manager:created_by_manager_id(first_name, last_name)
            ''')
            .inFilter('id', memberProjectIds)
            .order('created_at', ascending: false);

        memberProjects = (memberProjectsData as List)
            .map((json) => ProjectModel.fromJson(json))
            .toList();
      }

      // Combine and deduplicate
      final allProjects = <String, ProjectModel>{};
      for (final p in (ownProjects as List).map((json) => ProjectModel.fromJson(json))) {
        allProjects[p.id] = p;
      }
      for (final p in memberProjects) {
        allProjects[p.id] = p;
      }

      final result = allProjects.values.toList();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return await _enrichWithCounts(result);
    } catch (e) {
      print('Error fetching projects for manager: $e');
      return [];
    }
  }

  /// Get a single project by ID with details
  Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final response = await _supabase.projectsTable
          .select('''
            *,
            creator_super_admin:created_by_super_admin_id(first_name, last_name),
            creator_manager:created_by_manager_id(first_name, last_name)
          ''')
          .eq('id', projectId)
          .single();

      return ProjectModel.fromJson(response);
    } catch (e) {
      print('Error fetching project: $e');
      return null;
    }
  }

  /// Update project details
  Future<bool> updateProject({
    required String projectId,
    String? name,
    String? subtitle,
    String? instruction,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (subtitle != null) data['subtitle'] = subtitle;
      if (instruction != null) data['instruction'] = instruction;
      if (isActive != null) data['is_active'] = isActive;

      if (data.isEmpty) return true;

      await _supabase.projectsTable
          .update(data)
          .eq('id', projectId);

      return true;
    } catch (e) {
      print('Error updating project: $e');
      return false;
    }
  }

  /// Delete a project
  Future<bool> deleteProject(String projectId) async {
    try {
      final response = await _supabase.projectsTable
          .delete()
          .eq('id', projectId)
          .select();
      
      if (response == null || (response as List).isEmpty) {
        print('Error deleting project: RLS or not found');
        return false;
      }
      return true;
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  /// Get all projects an Employee is assigned to
  Future<List<ProjectModel>> getProjectsForEmployee(String employeeId) async {
    try {
      final assignments = await _supabase.client
          .from('project_callers')
          .select('project_id')
          .eq('employee_id', employeeId);
          
      final projectIds = (assignments as List)
          .map((a) => a['project_id'] as String)
          .toList();
          
      if (projectIds.isEmpty) return [];

      final data = await _supabase.projectsTable
          .select()
          .inFilter('id', projectIds)
          .order('created_at', ascending: false);

      return (data as List).map((json) => ProjectModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching employee projects: $e');
      return [];
    }
  }

  // ============================================
  // PROJECT MEMBERS / INVITATIONS
  // ============================================

  /// Invite a manager to a project (by Super Admin)
  Future<ProjectMemberModel?> inviteManagerToProject({
    required String projectId,
    required String managerId,
    String? superAdminId,
    String? inviterManagerId,
    bool canUpload = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'project_id': projectId,
        'manager_id': managerId,
        'role': 'member',
        'status': 'pending',
        'visible_to_super_admin': superAdminId != null,
        'can_upload': canUpload,
      };

      if (superAdminId != null) {
        data['invited_by_super_admin_id'] = superAdminId;
      } else if (inviterManagerId != null) {
        data['invited_by_manager_id'] = inviterManagerId;
      }

      final response = await _supabase.projectMembersTable
          .insert(data)
          .select('''
            *,
            manager:manager_id(first_name, last_name, email),
            project:project_id(name)
          ''')
          .single();

      // Also send a notification to the manager
      await _sendProjectInvitationNotification(
        managerId: managerId,
        projectId: projectId,
        inviterSuperAdminId: superAdminId,
        inviterManagerId: inviterManagerId,
      );

      return ProjectMemberModel.fromJson(response);
    } catch (e) {
      print('Error inviting manager to project: $e');
      rethrow;
    }
  }

  /// Accept a project invitation (by Manager)
  Future<bool> acceptInvitation(String membershipId) async {
    try {
      await _supabase.projectMembersTable
          .update({'status': 'accepted'})
          .eq('id', membershipId);

      // Notify the inviter
      final membership = await _supabase.projectMembersTable
          .select('''
            *,
            project:project_id(name),
            manager:manager_id(first_name, last_name)
          ''')
          .eq('id', membershipId)
          .single();

      final member = ProjectMemberModel.fromJson(membership);
      
      // If invited by super admin, notify them
      if (member.invitedBySuperAdminId != null) {
        try {
          await _supabase.notificationsTable.insert({
            'super_admin_id': member.invitedBySuperAdminId,
            'title': 'Invitation Accepted',
            'body': '${member.managerName ?? 'A manager'} accepted the invitation to project "${member.projectName}"',
            'type': 'project_invitation_accepted',
            'metadata': {
              'project_id': member.projectId,
              'manager_id': member.managerId,
            },
          });
        } catch (e) {
          print('Error sending acceptance notification to SA: $e');
        }
      }

      // If invited by another manager, notify them
      if (member.invitedByManagerId != null) {
        try {
          await _supabase.notificationsTable.insert({
            'manager_id': member.invitedByManagerId,
            'title': 'Invitation Accepted',
            'body': '${member.managerName ?? 'A manager'} accepted the invitation to project "${member.projectName}"',
            'type': 'project_invitation_accepted',
            'metadata': {
              'project_id': member.projectId,
              'manager_id': member.managerId,
            },
          });
        } catch (e) {
          print('Error sending acceptance notification to Manager: $e');
        }
      }

      return true;
    } catch (e) {
      print('Error accepting invitation: $e');
      return false;
    }
  }

  /// Decline a project invitation (by Manager)
  Future<bool> declineInvitation(String membershipId) async {
    try {
      await _supabase.projectMembersTable
          .update({'status': 'declined'})
          .eq('id', membershipId);

      // Notify the inviter
      final membership = await _supabase.projectMembersTable
          .select('''
            *,
            project:project_id(name),
            manager:manager_id(first_name, last_name)
          ''')
          .eq('id', membershipId)
          .single();

      final member = ProjectMemberModel.fromJson(membership);
      
      if (member.invitedBySuperAdminId != null) {
        try {
          await _supabase.notificationsTable.insert({
            'super_admin_id': member.invitedBySuperAdminId,
            'title': 'Invitation Declined',
            'body': '${member.managerName ?? 'A manager'} declined the invitation to project "${member.projectName}"',
            'type': 'project_invitation_declined',
            'metadata': {
              'project_id': member.projectId,
              'manager_id': member.managerId,
            },
          });
        } catch (e) {
          print('Error sending decline notification to SA: $e');
        }
      }

      if (member.invitedByManagerId != null) {
        try {
          await _supabase.notificationsTable.insert({
            'manager_id': member.invitedByManagerId,
            'title': 'Invitation Declined',
            'body': '${member.managerName ?? 'A manager'} declined the invitation to project "${member.projectName}"',
            'type': 'project_invitation_declined',
            'metadata': {
              'project_id': member.projectId,
              'manager_id': member.managerId,
            },
          });
        } catch (e) {
          print('Error sending decline notification to Manager: $e');
        }
      }

      return true;
    } catch (e) {
      print('Error declining invitation: $e');
      return false;
    }
  }

  /// Toggle visibility of a manager-created project to super admin
  Future<bool> toggleVisibilityToSuperAdmin({
    required String membershipId,
    required bool visible,
  }) async {
    try {
      await _supabase.projectMembersTable
          .update({'visible_to_super_admin': visible})
          .eq('id', membershipId);
      return true;
    } catch (e) {
      print('Error toggling visibility: $e');
      return false;
    }
  }

  /// Toggle upload permission for a manager in a project (by Super Admin)
  Future<bool> toggleUploadPermission({
    required String membershipId,
    required bool canUpload,
  }) async {
    try {
      await _supabase.projectMembersTable
          .update({'can_upload': canUpload})
          .eq('id', membershipId);
      return true;
    } catch (e) {
      print('Error toggling upload permission: $e');
      return false;
    }
  }

  /// Get pending invitations for a manager
  Future<List<ProjectMemberModel>> getPendingInvitations(String managerId) async {
    try {
      final response = await _supabase.projectMembersTable
          .select('''
            *,
            manager:manager_id(first_name, last_name, email),
            project:project_id(name, subtitle),
            inviter_super_admin:invited_by_super_admin_id(first_name, last_name),
            inviter_manager:invited_by_manager_id(first_name, last_name)
          ''')
          .eq('manager_id', managerId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProjectMemberModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching pending invitations: $e');
      return [];
    }
  }

  /// Get members of a project
  Future<List<ProjectMemberModel>> getProjectMembers(String projectId) async {
    try {
      final response = await _supabase.projectMembersTable
          .select('''
            *,
            manager:manager_id(first_name, last_name, email, is_active),
            inviter_super_admin:invited_by_super_admin_id(first_name, last_name),
            inviter_manager:invited_by_manager_id(first_name, last_name)
          ''')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ProjectMemberModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching project members: $e');
      return [];
    }
  }

  /// Get a single manager's own membership record for a project.
  /// Safe to call even on SA-created projects because RLS only returns
  /// rows where manager_id = your own ID.
  Future<ProjectMemberModel?> getMyMembershipForProject({
    required String projectId,
    required String managerId,
  }) async {
    try {
      final response = await _supabase.projectMembersTable
          .select('''
            *,
            manager:manager_id(first_name, last_name, email, is_active),
            inviter_super_admin:invited_by_super_admin_id(first_name, last_name),
            inviter_manager:invited_by_manager_id(first_name, last_name)
          ''')
          .eq('project_id', projectId)
          .eq('manager_id', managerId)
          .maybeSingle();

      if (response == null) return null;
      return ProjectMemberModel.fromJson(response);
    } catch (e) {
      print('Error fetching my membership: $e');
      return null;
    }
  }

  /// Remove a member from a project
  Future<bool> removeMember(String membershipId) async {
    try {
      await _supabase.projectMembersTable.delete().eq('id', membershipId);
      return true;
    } catch (e) {
      print('Error removing member: $e');
      return false;
    }
  }

  /// Get managers created by this Super Admin only (no agencies).
  Future<List<ManagerModel>> getAllManagers({String? currentSuperAdminId}) async {
    try {
      var query = _supabase.managersTable.select().eq('is_active', true);
          
      if (currentSuperAdminId != null) {
        // Only managers created by this SA — agencies are separate
        query = query.eq('created_by_super_admin_id', currentSuperAdminId);
      }
      
      final response = await query.order('first_name');

      return (response as List)
          .map((json) => ManagerModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching managers: $e');
      return [];
    }
  }

  /// Get managers not yet in a specific project.
  /// Returns BOTH SA-created managers AND agencies so the invite sheet tabs can filter.
  Future<List<ManagerModel>> getAvailableManagersForProject(String projectId, {String? currentSuperAdminId}) async {
    try {
      // Get managers already in this project
      final existingMembers = await _supabase.projectMembersTable
          .select('manager_id')
          .eq('project_id', projectId);

      final existingManagerIds = (existingMembers as List)
          .map((m) => m['manager_id'] as String)
          .toList();

      // Get both SA-created managers AND agencies
      var query = _supabase.managersTable.select().eq('is_active', true);
      if (currentSuperAdminId != null) {
        query = query.or('created_by_super_admin_id.eq.$currentSuperAdminId,created_by_super_admin_id.is.null');
      }
      final response = await query.order('first_name');
      final allManagers = (response as List)
          .map((json) => ManagerModel.fromJson(json))
          .toList();

      // Filter out already-invited managers
      return allManagers
          .where((m) => !existingManagerIds.contains(m.id))
          .toList();
    } catch (e) {
      print('Error fetching available managers: $e');
      return [];
    }
  }

  // ============================================
  // PROJECT STATS
  // ============================================

  /// Get batch count for a project
  Future<int> getProjectBatchCount(String projectId) async {
    try {
      final response = await _supabase.leadBatchesTable
          .select('id')
          .eq('project_id', projectId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get lead count for a project
  Future<int> getProjectLeadCount(String projectId) async {
    try {
      final response = await _supabase.leadsTable
          .select('id')
          .eq('project_id', projectId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get member count for a project (accepted only)
  Future<int> getProjectMemberCount(String projectId) async {
    try {
      final response = await _supabase.projectMembersTable
          .select('id')
          .eq('project_id', projectId)
          .eq('status', 'accepted');
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Get project stats (batch count, lead count, member count)
  Future<Map<String, int>> getProjectStats(String projectId) async {
    final results = await Future.wait([
      getProjectBatchCount(projectId),
      getProjectLeadCount(projectId),
      getProjectMemberCount(projectId),
    ]);

    return {
      'batchCount': results[0],
      'leadCount': results[1],
      'memberCount': results[2],
    };
  }

  /// Enrich a list of projects with batch count and member count.
  Future<List<ProjectModel>> _enrichWithCounts(List<ProjectModel> projects) async {
    final enriched = <ProjectModel>[];
    for (final project in projects) {
      try {
        final counts = await Future.wait([
          getProjectBatchCount(project.id),
          getProjectMemberCount(project.id),
        ]);
        enriched.add(project.copyWith(
          batchCount: counts[0],
          memberCount: counts[1],
        ));
      } catch (_) {
        enriched.add(project);
      }
    }
    return enriched;
  }

  // ============================================
  // HELPERS
  // ============================================

  /// Send a notification to a manager about a project invitation
  Future<void> _sendProjectInvitationNotification({
    required String managerId,
    required String projectId,
    String? inviterSuperAdminId,
    String? inviterManagerId,
  }) async {
    try {
      // Get project name
      final project = await _supabase.projectsTable
          .select('name')
          .eq('id', projectId)
          .single();

      final data = <String, dynamic>{
        'manager_id': managerId,
        'title': 'Project Invitation',
        'body': 'You have been invited to join project "${project['name']}"',
        'type': 'project_invitation',
        'metadata': {
          'project_id': projectId,
        },
      };

      if (inviterSuperAdminId != null) {
        data['super_admin_id'] = null; // recipient is manager_id, but inviter info can be in metadata if needed
      }

      await _supabase.notificationsTable.insert(data);
    } catch (e) {
      print('Error sending invitation notification: $e');
    }
  }

  // ============================================
  // PROJECT CALLERS (EMPLOYEE ASSIGNMENT)
  // ============================================

  /// Update caller assignment type for a project
  Future<bool> updateCallerAssignment({
    required String projectId,
    required String callerAssignment, // 'all' or 'selected'
  }) async {
    try {
      await _supabase.projectsTable
          .update({'caller_assignment': callerAssignment})
          .eq('id', projectId);
      return true;
    } catch (e) {
      print('Error updating caller assignment: $e');
      return false;
    }
  }

  /// Add an employee (caller) to a project
  Future<bool> addCallerToProject({
    required String projectId,
    required String employeeId,
    required String managerId,
  }) async {
    try {
      await _supabase.projectCallersTable.insert({
        'project_id': projectId,
        'employee_id': employeeId,
        'added_by_manager_id': managerId,
      });
      return true;
    } catch (e) {
      print('Error adding caller to project: $e');
      return false;
    }
  }

  /// Remove an employee (caller) from a project
  Future<bool> removeCallerFromProject({
    required String projectId,
    required String employeeId,
  }) async {
    try {
      await _supabase.projectCallersTable
          .delete()
          .eq('project_id', projectId)
          .eq('employee_id', employeeId);
      return true;
    } catch (e) {
      print('Error removing caller from project: $e');
      return false;
    }
  }

  /// Get all callers assigned to a project
  Future<List<Map<String, dynamic>>> getProjectCallers(String projectId) async {
    try {
      final response = await _supabase.projectCallersTable
          .select('''
            *,
            employee:employee_id(id, first_name, last_name, email, phone, is_active)
          ''')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching project callers: $e');
      return [];
    }
  }

  /// Get manager's employees that are NOT yet added to a project
  Future<List<Map<String, dynamic>>> getAvailableCallersForProject({
    required String projectId,
    required String managerId,
  }) async {
    try {
      // Get employees already in this project
      final existingCallers = await _supabase.projectCallersTable
          .select('employee_id')
          .eq('project_id', projectId);

      final existingIds = (existingCallers as List)
          .map((c) => c['employee_id'] as String)
          .toList();

      // Get all active employees under this manager
      var query = _supabase.employeesTable
          .select()
          .eq('manager_id', managerId)
          .eq('is_active', true);

      final allEmployees = await query.order('first_name');

      // Filter out already-added employees
      return List<Map<String, dynamic>>.from(
        (allEmployees as List).where((e) => !existingIds.contains(e['id'])),
      );
    } catch (e) {
      print('Error fetching available callers: $e');
      return [];
    }
  }

  /// Add multiple callers to a project at once
  Future<bool> addAllCallersToProject({
    required String projectId,
    required String managerId,
  }) async {
    try {
      // Get all active employees of this manager
      final employees = await _supabase.employeesTable
          .select('id')
          .eq('manager_id', managerId)
          .eq('is_active', true);

      // Get existing callers to avoid duplicates
      final existingCallers = await _supabase.projectCallersTable
          .select('employee_id')
          .eq('project_id', projectId);

      final existingIds = (existingCallers as List)
          .map((c) => c['employee_id'] as String)
          .toSet();

      // Add new callers
      final newCallers = (employees as List)
          .where((e) => !existingIds.contains(e['id']))
          .map((e) => {
                'project_id': projectId,
                'employee_id': e['id'],
                'added_by_manager_id': managerId,
              })
          .toList();

      if (newCallers.isNotEmpty) {
        await _supabase.projectCallersTable.insert(newCallers);
      }

      return true;
    } catch (e) {
      print('Error adding all callers: $e');
      return false;
    }
  }

  /// Remove all callers from a project
  Future<bool> removeAllCallersFromProject(String projectId) async {
    try {
      await _supabase.projectCallersTable
          .delete()
          .eq('project_id', projectId);
      return true;
    } catch (e) {
      print('Error removing all callers: $e');
      return false;
    }
  }
}
