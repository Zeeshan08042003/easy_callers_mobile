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
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribute_leads_binding.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribution_details_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribution_details_binding.dart';
import 'package:easy_callers_mobile/features/project/controllers/project_list_controller.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';

/// Controller for the project detail view.
class ProjectDetailController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<ProjectModel?> project = Rx<ProjectModel?>(null);
  final RxList<ProjectMemberModel> members = <ProjectMemberModel>[].obs;
  final RxList<LeadBatchModel> batches = <LeadBatchModel>[].obs;
  final RxList<ManagerModel> availableManagers = <ManagerModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  // Caller (employee) management
  final RxList<EmployeeModel> projectCallers = <EmployeeModel>[].obs;
  final RxList<EmployeeModel> availableCallers = <EmployeeModel>[].obs;
  final RxString callerAssignment = 'all'.obs; // 'all' or 'selected'

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
    } catch (e) {
      print('Error fetching project details: $e');
      Get.snackbar('Error', 'Failed to load project details');
    } finally {
      isLoading.value = false;
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
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        barrierDismissible: false,
      );
      
      final leadService = Get.find<LeadService>();
      final unassignedIds = await leadService.getUnassignedLeadsFromBatch(batch.id);
      
      if (Get.isDialogOpen ?? false) Get.back(); // close dialog
      
      if (unassignedIds.isNotEmpty) {
        // Still has unassigned leads -> Distribute
        await Get.to(
          () => const DistributeLeadsView(), 
          binding: DistributeLeadsBinding(),
          arguments: batch,
        );
        // Refresh batch list to update counts if distribution occurred
        _fetchBatches();
      } else {
        // Fully distributed -> View details
        Get.to(
          () => const DistributionDetailsView(),
          binding: DistributionDetailsBinding(),
          arguments: batch,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
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
      final callers = data
          .where((d) => d['employee'] != null && d['employee'] is Map)
          .map((d) => EmployeeModel.fromJson(d['employee'] as Map<String, dynamic>))
          .toList();
      projectCallers.value = callers;
      return callers;
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

  /// Remove a caller from the project
  Future<void> removeCaller(String employeeId) async {
    try {
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

  // ============================================
  // LEAD UPLOAD
  // ============================================

  Future<void> uploadLeadsToProject() async {
    try {
      isUploading.value = true;

      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) {
        Get.snackbar('Error', 'Manager profile not found');
        return;
      }

      if (projectId == null) {
        Get.snackbar('Error', 'No project selected');
        return;
      }

      final batch = await _leadService.pickAndUploadLeadsToProject(
        managerId: managerId,
        projectId: projectId!,
      );

      if (batch != null) {
        Get.snackbar(
          'Success',
          'Uploaded ${batch.totalLeads} leads to project!',
          duration: const Duration(seconds: 3),
        );
        await fetchProjectDetails();
      }
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteBatch(String batchId) async {
    try {
      final success = await _leadService.deleteLeadBatch(batchId);
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
      final superAdminId = isSuperAdmin ? _authService.currentSuperAdmin.value?.id : null;
      availableManagers.value = await _projectService
          .getAvailableManagersForProject(projectId!, superAdminId: superAdminId);
    } catch (e) {
      print('Error loading available managers: $e');
    }
  }

  Future<void> inviteManager(String managerId) async {
    try {
      final saId = _authService.currentSuperAdmin.value?.id;
      if (saId == null) {
        Get.snackbar('Error', 'Super Admin profile not found');
        return;
      }

      await _projectService.inviteManagerToProject(
        projectId: projectId!,
        managerId: managerId,
        superAdminId: saId,
      );

      Get.snackbar('Success', 'Manager invited successfully!');
      await fetchProjectDetails();
      await loadAvailableManagers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to invite manager: $e');
    }
  }

  Future<void> removeMember(String membershipId) async {
    try {
      final success = await _projectService.removeMember(membershipId);
      if (success) {
        Get.snackbar('Done', 'Member removed from project');
        await fetchProjectDetails();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove member: $e');
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
  bool get isManager => _authService.currentRole.value == UserRole.manager;
  String? get currentManagerId => _authService.currentManager.value?.id;

  bool get canInviteManagers {
    if (isSuperAdmin && project.value?.isCreatedBySuperAdmin == true) {
      return true;
    }
    if (isManager && project.value?.createdByManagerId == _authService.currentManager.value?.id) {
      return true;
    }
    return false;
  }

  bool get canUploadLeads {
    if (isManager) return true;
    if (isSuperAdmin) return true;
    return false;
  }

  bool get canManageCallers {
    if (isManager && project.value?.createdByManagerId == _authService.currentManager.value?.id) {
      return true;
    }
    if (isSuperAdmin && project.value?.isCreatedBySuperAdmin == true) {
      return true;
    }
    return false;
  }

  bool get canDeleteProject {
    if (project.value == null) return false;
    if (isManager && project.value!.createdByManagerId == _authService.currentManager.value?.id) {
      return true;
    }
    if (isSuperAdmin && project.value!.isCreatedBySuperAdmin == true) {
      return true;
    }
    return false;
  }
}
