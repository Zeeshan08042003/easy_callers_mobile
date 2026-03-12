import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/project/models/project_member_model.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/services/background_upload_manager.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/batch_leads_view.dart';
import 'package:easy_callers_mobile/features/super_admin/batch_analytics/views/sa_batch_analytics_view.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_list_controller.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';

/// Controller for the project detail view.
class ProjectDetailController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final WebService _webService = Get.find<WebService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<ProjectModel?> project = Rx<ProjectModel?>(null);
  final RxList<ProjectMemberModel> members = <ProjectMemberModel>[].obs;
  final RxList<LeadBatchModel> batches = <LeadBatchModel>[].obs;
  final RxList<ManagerModel> availableManagers = <ManagerModel>[].obs;
  final RxList<ManagerModel> filteredAvailableManagers = <ManagerModel>[].obs;
  final RxString managerSearchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  // Caller (employee) management
  final RxList<EmployeeModel> projectCallers = <EmployeeModel>[].obs;
  final RxList<EmployeeModel> availableCallers = <EmployeeModel>[].obs;
  final RxString callerAssignment = 'all'.obs; // 'all' or 'selected'

  // The current manager's own membership in this project (null if not a member)
  final Rx<ProjectMemberModel?> myMembership = Rx<ProjectMemberModel?>(null);

  // Stats
  final RxInt leadCount = 0.obs;
  final RxInt batchCount = 0.obs;

  String? projectId;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments is ProjectModel) {
        project.value = Get.arguments as ProjectModel;
        projectId = project.value!.id;
        callerAssignment.value = project.value!.callerAssignment;
      } else if (Get.arguments is String) {
        projectId = Get.arguments as String;
      }
    }
    if (projectId != null) {
      fetchProjectDetails();
    }
  }

  Future<void> fetchProjectDetails() async {
    try {
      isLoading.value = true;

      // Fetch all data in parallel
      final results = await Future.wait([
        _projectService.getProjectById(projectId!),
        _projectService.getProjectMembers(projectId!),
        _projectService.getProjectStats(projectId!),
        _fetchBatches(),
        _fetchProjectCallers(),
      ]);

      project.value = results[0] as ProjectModel?;
      members.value = results[1] as List<ProjectMemberModel>;
      final stats = results[2] as Map<String, int>;
      leadCount.value = stats['leadCount'] ?? 0;
      batchCount.value = stats['batchCount'] ?? 0;

      if (project.value != null) {
        callerAssignment.value = project.value!.callerAssignment;
      }

      // For managers: resolve their own membership.
      // 1) Try to find it in the already-loaded members list.
      // 2) If not present (e.g. RLS filtered it out), query directly.
      if (isManager) {
        final myId = _authService.currentManager.value?.id;
        if (myId != null) {
          final fromList = members.firstWhereOrNull((m) => m.managerId == myId);
          if (fromList != null) {
            myMembership.value = fromList;
          } else {
            myMembership.value = await _fetchMyMembership();
          }
        }
      }
    } catch (e) {
      print('Error fetching project details: $e');
      Get.snackbar('Error', 'Failed to load project details');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch the current manager's own membership record for this project.
  /// Queries the DB directly so it works even when the members list is empty/restricted.
  Future<ProjectMemberModel?> _fetchMyMembership() async {
    try {
      final myId = _authService.currentManager.value?.id;
      if (myId == null) return null;

      return await _projectService.getMyMembershipForProject(
        projectId: projectId!,
        managerId: myId,
      );
    } catch (e) {
      print('Error fetching my membership: $e');
      return null;
    }
  }

  Future<List<LeadBatchModel>> _fetchBatches() async {
    try {
      final response = await Get.find<SupabaseService>()
          .leadBatchesTable
          .select('''
            *,
            managers:uploaded_by(first_name, last_name)
          ''')
          .eq('project_id', projectId!)
          .order('created_at', ascending: false);

      final result = (response as List)
          .map((json) => LeadBatchModel.fromJson(json))
          .toList();
      batches.value = result;
      return result;
    } catch (e) {
      print('Error fetching batches: $e');
      return [];
    }
  }

  Future<void> handleBatchTap(LeadBatchModel batch) async {
    try {
      if (isSuperAdmin) {
        // SA gets the analytics view with manager filter + status tabs
        Get.to(
          () => const SABatchAnalyticsView(),
          arguments: batch,
        );
        return;
      }

      // For managers: always show the tabbed leads view 
      // (filtered to their own employees' leads)
      Get.to(
        () => const BatchLeadsView(),
        arguments: batch,
      );
    } catch (e) {
      print('Error checking batch status: $e');
      Get.snackbar('Error', 'Failed to open batch details');
    }
  }


  // ============================================
  // CALLER (EMPLOYEE) MANAGEMENT
  // ============================================

  Future<List<EmployeeModel>> _fetchProjectCallers() async {
    try {
      final data = await _projectService.getProjectCallers(projectId!);
      var callers = data
          .where((d) => d['employee'] != null && d['employee'] is Map)
          .toList();

      // For managers, only show THEIR OWN callers
      // Super admins see all callers (isSuperAdmin check)
      final managerId = _authService.currentManager.value?.id;
      if (managerId != null && !isSuperAdmin) {
        callers = callers.where((d) {
          // Check if this caller was added by the current manager
          final addedBy = d['added_by_manager_id'] as String?;
          if (addedBy == managerId) return true;

          // Fallback: check if the employee belongs to this manager
          final emp = d['employee'] as Map<String, dynamic>;
          return emp['manager_id'] == managerId;
        }).toList();
      }

      final callerModels = callers
          .map((d) => EmployeeModel.fromJson(d['employee'] as Map<String, dynamic>))
          .toList();
      projectCallers.value = callerModels;
      return callerModels;
    } catch (e) {
      print('Error fetching project callers: $e');
      return [];
    }
  }

  /// Toggle between "all" and "selected" caller assignment
  Future<void> toggleCallerAssignment(String type) async {
    try {
      final managerId = _authService.currentManager.value?.id;

      final success = await _projectService.updateCallerAssignment(
        projectId: projectId!,
        callerAssignment: type,
      );

      if (success) {
        callerAssignment.value = type;

        // If switching to "all", add all manager's employees
        if (type == 'all' && managerId != null) {
          await _projectService.addAllCallersToProject(
            projectId: projectId!,
            managerId: managerId,
          );
        }

        await _fetchProjectCallers();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update caller assignment');
    }
  }

  /// Load available employees for adding to project
  Future<void> loadAvailableCallers() async {
    try {
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) return;

      final data = await _projectService.getAvailableCallersForProject(
        projectId: projectId!,
        managerId: managerId,
      );
      availableCallers.value = data
          .map((json) => EmployeeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error loading available callers: $e');
    }
  }

  /// Add a single caller to the project
  Future<void> addCaller(String employeeId) async {
    try {
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) return;

      final success = await _projectService.addCallerToProject(
        projectId: projectId!,
        employeeId: employeeId,
        managerId: managerId,
      );

      if (success) {
        Get.snackbar('Success', 'Caller added to project');
        await _fetchProjectCallers();
        await loadAvailableCallers();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add caller');
    }
  }

  /// Remove a caller from the project.
  /// Checks for assigned leads first and offers redistribution options.
  Future<void> removeCaller(String employeeId) async {
    try {
      // First, check if this employee has any leads assigned in this project
      final employeeLeads = (await _webService.getLeadsCountByEmployee(
        employeeId,
        projectId: projectId,
      )).payload ?? 0;

      if (employeeLeads > 0) {
        // Show redistribution dialog
        final result = await _showLeadRedistributionDialog(
          employeeId: employeeId,
          leadCount: employeeLeads,
        );
        if (result == null) return; // User cancelled
      } else {
        // No leads — just confirm removal
        final confirm = await Get.dialog<bool>(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Remove Caller', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Are you sure you want to remove this caller from the project?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm != true) return;
      }

      // Proceed with removal
      final success = await _projectService.removeCallerFromProject(
        projectId: projectId!,
        employeeId: employeeId,
      );

      if (success) {
        Get.snackbar('Done', 'Caller removed from project');
        await _fetchProjectCallers();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove caller');
    }
  }

  /// Show a dialog for choosing what to do with leads when removing a caller.
  /// Returns true if user confirms, null if cancelled.
  Future<bool?> _showLeadRedistributionDialog({
    required String employeeId,
    required int leadCount,
  }) async {
    // Get the other callers in this project (excluding the one being removed)
    final otherCallers = projectCallers
        .where((c) => c.id != employeeId && c.isActive)
        .toList();

    return await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leads Found',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: 'This caller has '),
                  TextSpan(
                    text: '$leadCount lead${leadCount != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ' assigned in this project.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do?',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // Option 1: Redistribute equally
            if (otherCallers.isNotEmpty) ...[
              _buildRedistributeOption(
                icon: Icons.share_rounded,
                title: 'Redistribute to other callers',
                subtitle: 'Split ${leadCount} lead${leadCount != 1 ? 's' : ''} among ${otherCallers.length} remaining caller${otherCallers.length != 1 ? 's' : ''}',
                onTap: () async {
                  Get.back(result: true);
                  await _redistributeLeads(
                    employeeId: employeeId,
                    targetEmployees: otherCallers,
                  );
                },
              ),
              const SizedBox(height: 8),
            ],

            // Option 2: Leave unassigned
            _buildRedistributeOption(
              icon: Icons.person_remove_rounded,
              title: 'Unassign leads & remove caller',
              subtitle: 'Leads will become unassigned and can be distributed later',
              onTap: () async {
                Get.back(result: true);
                await _unassignEmployeeLeads(
                  employeeId: employeeId,
                );
              },
            ),
            const SizedBox(height: 8),

            // Option 3: Keep as is (just remove from project)
            _buildRedistributeOption(
              icon: Icons.exit_to_app_rounded,
              title: 'Remove without changing leads',
              subtitle: 'Leads stay assigned to the caller even though they are removed',
              onTap: () => Get.back(result: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildRedistributeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Redistribute leads from removed employee to other callers in the project
  Future<void> _redistributeLeads({
    required String employeeId,
    required List<EmployeeModel> targetEmployees,
  }) async {
    try {
      isLoading.value = true;

      // Get all leads assigned to this employee in this project
      final leadsList = (await _webService.getLeadsByEmployee(
        employeeId,
        projectId: projectId,
        page: 1,
        pageSize: 10000, // Get all
      )).payload ?? [];

      if (leadsList.isEmpty || targetEmployees.isEmpty) return;

      // Distribute equally among target employees
      final leadIds = leadsList.map((l) => l.id).toList();
      final targetIds = targetEmployees.map((e) => e.id).toList();

      await _webService.splitLeadsEqually(
        leadIds: leadIds,
        employeeIds: targetIds,
      );

      Get.snackbar(
        'Redistributed',
        '${leadsList.length} lead${leadsList.length != 1 ? 's' : ''} redistributed to ${targetEmployees.length} caller${targetEmployees.length != 1 ? 's' : ''}',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to redistribute leads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Unassign all leads for a specific employee in this project
  Future<void> _unassignEmployeeLeads({
    required String employeeId,
  }) async {
    try {
      isLoading.value = true;

      // Get all leads assigned to this employee in this project
      final leadsList = (await _webService.getLeadsByEmployee(
        employeeId,
        projectId: projectId,
        page: 1,
        pageSize: 10000, // Get all
      )).payload ?? [];

      if (leadsList.isEmpty) return;

      // Unassign all leads
      final supabase = Get.find<SupabaseService>();
      final leadIds = leadsList.map((l) => l.id).toList();

      // Update in chunks to avoid URL length limits
      const chunkSize = 50;
      for (var i = 0; i < leadIds.length; i += chunkSize) {
        final end = (i + chunkSize < leadIds.length) ? i + chunkSize : leadIds.length;
        final chunk = leadIds.sublist(i, end);
        await supabase.leadsTable
            .update({
              'assigned_to': null,
              'status': 'new',
            })
            .inFilter('id', chunk);
      }

      Get.snackbar(
        'Unassigned',
        '${leadsList.length} lead${leadsList.length != 1 ? 's' : ''} are now unassigned and ready for redistribution',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to unassign leads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // LEAD UPLOAD
  // ============================================

  Future<void> uploadLeadsToProject() async {
    if (!canUploadLeads) {
      Get.snackbar('Permission Denied', 'You do not have permission to upload leads to this project.');
      return;
    }

    final managerId = _authService.currentManager.value?.id;
    final superAdminId = _authService.currentSuperAdmin.value?.id;

    if (managerId == null && superAdminId == null) {
      Get.snackbar('Error', 'Profile not found');
      return;
    }

    if (projectId == null) {
      Get.snackbar('Error', 'No project selected');
      return;
    }

    try {
      isUploading.value = true;
      
      // Use background upload manager — file picker opens immediately,
      // upload runs in background so the user can keep using the app.
      final uploadManager = Get.find<BackgroundUploadManager>();
      await uploadManager.startUpload(
        managerId: managerId,
        projectId: projectId!,
        projectName: project.value?.name,
      );

      // Refresh project details after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        fetchProjectDetails();
      });
    } catch (e) {
      print('Error starting upload: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteBatch(String batchId) async {
    try {
      final success = (await _webService.deleteLeadBatch(batchId)).payload ?? false;
      if (success) {
        _showSnack('Success', 'Excel sheet and associated leads deleted');
        await fetchProjectDetails();
      } else {
        _showSnack('Error', 'Failed to delete excel sheet', isError: true);
      }
    } catch (e) {
      _showSnack('Error', 'An unexpected error occurred', isError: true);
    }
  }

  Future<void> deleteProject() async {
    if (projectId == null) return;
    
    try {
      isLoading.value = true;
      final success = await _projectService.deleteProject(projectId!);
      
      if (success) {
        // Refresh project list if it exists
        if (Get.isRegistered<ProjectListController>()) {
          Get.find<ProjectListController>().fetchProjects();
        }
        // Refresh manager dashboard
        if (Get.isRegistered<ManagerDashboardController>()) {
          Get.find<ManagerDashboardController>().fetchProjects();
        }
        
        Get.back(); // Go back from project detail
        _showSnack('Success', 'Project deleted successfully');
      } else {
        _showSnack('Error', 'Failed to delete project. You may not have permission.', isError: true);
      }
    } catch (e) {
      _showSnack('Error', 'An error occurred while deleting project', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================
  // MANAGER INVITATION
  // ============================================

  Future<void> loadAvailableManagers() async {
    try {
      // For Super Admin, we show ALL available managers (their own + independent ones)
      // For Managers, we might only show managers they created (if that's a thing) 
      // but usually managers can't invite other managers.
      
      // If Super Admin, pass their ID to get own + independent managers
      final saId = _authService.currentSuperAdmin.value?.id;
      final currentManagerId = _authService.currentManager.value?.id;
      
      final result = await _projectService
          .getAvailableManagersForProject(projectId!, currentSuperAdminId: saId);
      
      // Filter out the current user themselves
      availableManagers.assignAll(
        result.where((m) => m.id != currentManagerId).toList()
      );
      
      _applyManagerSearch();
    } catch (e) {
      print('Error loading available managers: $e');
    }
  }

  void searchManagers(String query) {
    managerSearchQuery.value = query;
    _applyManagerSearch();
  }

  void _applyManagerSearch() {
    if (managerSearchQuery.value.isEmpty) {
      filteredAvailableManagers.value = availableManagers.toList();
    } else {
      final query = managerSearchQuery.value.toLowerCase();
      filteredAvailableManagers.value = availableManagers.where((m) {
        return m.fullName.toLowerCase().contains(query) ||
            m.email.toLowerCase().contains(query);
      }).toList();
    }
  }

  Future<void> inviteManager(String managerId, {bool canUpload = false}) async {
    try {
      final saId = _authService.currentSuperAdmin.value?.id;
      final currentMgrId = _authService.currentManager.value?.id;

      if (saId == null && currentMgrId == null) {
        Get.snackbar('Error', 'Profile not found');
        return;
      }

      await _projectService.inviteManagerToProject(
        projectId: projectId!,
        managerId: managerId,
        superAdminId: saId,
        inviterManagerId: currentMgrId,
        canUpload: canUpload,
      );

      Get.snackbar('Success', 'Manager invited successfully!');
      await fetchProjectDetails();
      await loadAvailableManagers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to invite manager: $e');
    }
  }

  /// Toggle upload permission for a member (SA only)
  Future<void> toggleUploadPermission(String membershipId, bool canUpload) async {
    try {
      final success = await _projectService.toggleUploadPermission(
        membershipId: membershipId,
        canUpload: canUpload,
      );
      if (success) {
        Get.snackbar('Updated', canUpload ? 'Upload permission granted' : 'Upload permission revoked');
        await fetchProjectDetails();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update permission: $e');
    }
  }

  Future<void> removeMember(String membershipId) async {
    try {
      // Find the member being removed to get their managerId
      final memberToRemove = members.firstWhereOrNull((m) => m.id == membershipId);
      
      if (memberToRemove != null && projectId != null) {
        // Clean up leads and callers for this manager's employees in this project
        await _cleanupManagerLeadsAndCallers(memberToRemove.managerId);
      }

      final success = await _projectService.removeMember(membershipId);
      if (success) {
        Get.snackbar('Done', 'Member removed from project');
        await fetchProjectDetails();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove member: $e');
    }
  }

  /// When SA removes a manager from the project:
  /// 1. Unassign all leads that were assigned to this manager's employees in this project
  /// 2. Remove all project_callers entries for this manager's employees
  Future<void> _cleanupManagerLeadsAndCallers(String managerId) async {
    try {
      final supabase = Get.find<SupabaseService>();

      // 1. Get the manager's employees who are callers in this project
      final callersResponse = await supabase.projectCallersTable
          .select('employee_id')
          .eq('project_id', projectId!)
          .eq('added_by_manager_id', managerId);

      final callerEmployeeIds = (callersResponse as List)
          .map((c) => c['employee_id'] as String)
          .toList();

      if (callerEmployeeIds.isNotEmpty) {
        // 2. Unassign all leads assigned to these employees in this project
        //    Set them back to 'new' status so they can be redistributed
        //    Process in chunks to avoid URL length issues
        const chunkSize = 50;
        for (var i = 0; i < callerEmployeeIds.length; i += chunkSize) {
          final end = (i + chunkSize < callerEmployeeIds.length) 
              ? i + chunkSize 
              : callerEmployeeIds.length;
          final chunk = callerEmployeeIds.sublist(i, end);
          
          await supabase.leadsTable
              .update({
                'assigned_to': null,
                'status': 'new',
              })
              .eq('project_id', projectId!)
              .inFilter('assigned_to', chunk);
        }

        // 3. Remove all project_callers for this manager
        await supabase.projectCallersTable
            .delete()
            .eq('project_id', projectId!)
            .eq('added_by_manager_id', managerId);

        print('✅ Cleaned up ${callerEmployeeIds.length} callers and their leads for manager $managerId');
      }
    } catch (e) {
      print('⚠️ Error cleaning up manager leads/callers: $e');
      // Non-fatal: the member removal can still proceed
    }
  }

  void _showSnack(String title, String message, {bool isError = false}) {
    final ctx = Get.overlayContext ?? Get.context;

    if (ctx == null) return;

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================
  // PERMISSION HELPERS
  // ============================================

  bool get isSuperAdmin => _authService.currentRole.value == UserRole.superAdmin;
  bool get isManager => _authService.currentRole.value == UserRole.manager || 
                     _authService.currentRole.value == UserRole.agency;
  String? get currentManagerId => _authService.currentManager.value?.id;
  AuthService get authService => _authService;

  /// Whether I am the owner/creator of this project (manager who created it)
  bool get isProjectOwner {
    if (!isManager) return false;
    return project.value?.createdByManagerId == _authService.currentManager.value?.id;
  }

  /// Whether I am an accepted member of this project
  /// Works for both: manager-created and SA-created projects.
  bool get isAcceptedMember {
    if (!isManager) return false;
    // Owner role = automatically accepted
    if (isProjectOwner) return true;
    // Check the loaded members list first
    final myId = _authService.currentManager.value?.id;
    final fromList = members.firstWhereOrNull(
      (m) => m.managerId == myId && m.status == 'accepted',
    );
    if (fromList != null) return true;
    // Fall back to the separately fetched membership
    return myMembership.value?.status == 'accepted';
  }

  bool get canInviteManagers {
    if (isSuperAdmin && project.value?.isCreatedBySuperAdmin == true) {
      return true;
    }
    if (isProjectOwner) return true;
    return false;
  }

  bool get canUploadLeads {
    if (isSuperAdmin) return true;
    if (isManager) {
      // For manager-created projects: owner can always upload
      if (isProjectOwner) return true;
      // For SA-created projects: only if SA has granted can_upload permission
      if (project.value?.isCreatedBySuperAdmin == true) {
        return _myMembershipRecord?.canUpload == true;
      }
      // For other manager-created projects where I'm a member
      return isAcceptedMember;
    }
    return false;
  }

  /// Internal helper: get the resolved membership record for the current manager
  ProjectMemberModel? get _myMembershipRecord {
    final myId = _authService.currentManager.value?.id;
    if (myId == null) return null;
    // Try the members list first
    final fromList = members.firstWhereOrNull(
      (m) => m.managerId == myId,
    );
    return fromList ?? myMembership.value;
  }

  bool get canManageCallers {
    if (isSuperAdmin) return false; // Super admin adds managers, not callers
    // Manager can manage their own callers if they are an accepted member
    return isAcceptedMember;
  }

  bool get canDeleteProject {
    if (project.value == null) return false;
    if (isProjectOwner) return true;
    if (isSuperAdmin && project.value!.isCreatedBySuperAdmin == true) {
      return true;
    }
    return false;
  }
}
