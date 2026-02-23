import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/storage_service.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribute_leads_binding.dart';

class ManagerDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  
  // Optional manager ID for Super Admin oversight
  String? oversightManagerId;
  
  // ============================================
  // NAVIGATION
  // ============================================
  final RxInt currentTabIndex = 0.obs;
  
  void switchTab(int index) {
    currentTabIndex.value = index;
  }

  // ============================================
  // PROJECT SELECTION
  // ============================================
  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);
  final RxBool isLoadingProjects = false.obs;
  final RxBool hasNoProjects = false.obs;

  // ============================================
  // DASHBOARD DATA
  // ============================================
  final totalLeads = 0.obs;
  final leadsAssigned = 0.obs;
  final teamPerformance = 0.0.obs;

  final isLoading = false.obs;
  final Rx<LeadBatchModel?> lastUploadedBatch = Rx<LeadBatchModel?>(null);
  final unassignedCount = 0.obs;

  // Team members list
  final teamMembers = <Map<String, dynamic>>[].obs;

  // Weekly distribution data (M, T, W, T, F, S)
  final weeklyDistribution = <double>[0.5, 0.7, 0.4, 1.0, 0.8, 0.3].obs;

  // Last call activity across all team members
  final Rx<CallLogModel?> lastCallLog = Rx<CallLogModel?>(null);

  @override
  void onInit() {
    super.onInit();
    
    // Check if we are in oversight mode (passed from Super Admin)
    if (Get.arguments is String) {
      oversightManagerId = Get.arguments as String;
    } else if (Get.arguments is ManagerModel) {
      oversightManagerId = (Get.arguments as ManagerModel).id;
    }

    // Load projects first, then dashboard data
    fetchProjects();

    // Listen for manager changes (only if not in oversight mode)
    if (oversightManagerId == null) {
      ever(_authService.currentManager, (manager) {
        if (manager != null) {
          fetchProjects();
        }
      });
    }
  }

  // ============================================
  // PROJECT MANAGEMENT
  // ============================================

  /// Fetch all projects for the manager
  Future<void> fetchProjects() async {
    try {
      final managerId = oversightManagerId ?? _authService.currentManager.value?.id;
      if (managerId == null) {
        isLoadingProjects.value = false;
        return;
      }

      // Avoid redundant loads if not necessary, but refresh list
      isLoadingProjects.value = true;
      final result = await _projectService.getProjectsForManager(managerId);
      projects.value = result;

      if (result.isEmpty) {
        hasNoProjects.value = true;
        selectedProject.value = null;
        _clearDashboardData();
      } else {
        hasNoProjects.value = false;
        
        ProjectModel? toSelect;

        // 1. Try to keep current valid selection
        if (selectedProject.value != null) {
          toSelect = result.firstWhereOrNull((p) => p.id == selectedProject.value!.id);
        }

        // 2. Try to restore from storage
        if (toSelect == null) {
          final storageKey = 'last_project_id_$managerId';
          final savedId = _storage.getString(storageKey) ?? 
                          _storage.getString(StorageService.keyLastProjectID);
          
          if (savedId != null) {
            toSelect = result.firstWhereOrNull((p) => p.id == savedId);
          }
        }

        // 3. Fallback to first
        toSelect ??= result.first;

        // Only update if selection changed or first load
        if (selectedProject.value?.id != toSelect.id) {
          selectProject(toSelect);
        } else {
          // If we are keeping same project, just refresh dashboard data
          fetchDashboardData();
        }
      }
    } catch (e) {
      print('Error fetching projects: $e');
    } finally {
      isLoadingProjects.value = false;
    }
  }

  /// Select a project and refresh dashboard data
  void selectProject(ProjectModel project) {
    selectedProject.value = project;
    
    // Save to storage (specific to manager to avoid conflicts)
    final managerId = oversightManagerId ?? _authService.currentManager.value?.id;
    if (oversightManagerId == null && managerId != null) {
      _storage.setString('last_project_id_$managerId', project.id);
      // Also update the legacy global key for backward compatibility or simple cases
      _storage.setString(StorageService.keyLastProjectID, project.id);
    }
    
    fetchDashboardData();
  }

  void _clearDashboardData() {
    totalLeads.value = 0;
    leadsAssigned.value = 0;
    teamPerformance.value = 0.0;
    lastUploadedBatch.value = null;
    unassignedCount.value = 0;
    teamMembers.clear();
    weeklyDistribution.value = List.filled(6, 0.0);
    lastCallLog.value = null;
  }

  /// Called when a new project was just created
  void onProjectCreated(ProjectModel project) {
    projects.add(project);
    hasNoProjects.value = false;
    selectProject(project);
  }

  // ============================================
  // UPLOAD & DISTRIBUTE
  // ============================================

  Future<void> uploadLeads() async {
    if (selectedProject.value == null) {
      Get.snackbar('Error', 'Please select a project first');
      return;
    }

    try {
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) {
        Get.snackbar('Error', 'Manager profile not found');
        return;
      }

      isLoading.value = true;
      // Always upload to the selected project
      final batch = await _leadService.pickAndUploadLeadsToProject(
        managerId: managerId,
        projectId: selectedProject.value!.id,
      );

      if (batch != null) {
        lastUploadedBatch.value = batch;
        Get.snackbar(
          'Success',
          'Uploaded ${batch.totalLeads} leads to "${selectedProject.value!.name}"!\nClick "Distribute Leads" to assign them.',
          duration: const Duration(seconds: 4),
        );
        await fetchDashboardData();
      }
    } catch (e) {
      print("Upload Failed, ${e.toString()}");
      Get.snackbar('Upload Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> distributeLeads() async {
    final batch = lastUploadedBatch.value;
    if (batch == null) {
      Get.snackbar('Error', 'No batch to distribute');
      return;
    }

    try {
      isLoading.value = true;

      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) {
        Get.snackbar('Error', 'Manager profile not found');
        return;
      }

      print('🔍 Fetching employees for manager: $managerId');
      final employees = await _leadService.getEmployeesByManager(managerId);
      print('✅ Fetched ${employees.length} employees');

      if (employees.isEmpty) {
        isLoading.value = false;
        Get.snackbar(
          'No Employees Found',
          'Please add employees first before distributing leads',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      // Navigate to distribution screen
      isLoading.value = false;
      print('🚀 Navigating to distribution screen with batch: ${batch.id}');

      await Get.to(
        () => const DistributeLeadsView(),
        binding: DistributeLeadsBinding(),
        arguments: batch,
      );

      // Refresh after returning
      await fetchDashboardData();
    } catch (e, stackTrace) {
      print('❌ Error in distributeLeads: $e');
      print('📍 Stack trace: $stackTrace');
      Get.snackbar('Error', 'Failed to check employees: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void clearLastBatch() {
    lastUploadedBatch.value = null;
  }

  // ============================================
  // DASHBOARD DATA (filtered by selected project)
  // ============================================

  Future<void> fetchDashboardData() async {
    if (selectedProject.value == null) return;

    isLoading.value = true;

    try {
      final managerId = oversightManagerId ?? _authService.currentManager.value?.id;
      final projectId = selectedProject.value!.id;

      if (managerId != null) {
        // Fetch latest batch with unassigned leads FOR THIS PROJECT
        final batch = await _leadService.getLatestBatchWithUnassignedLeadsForProject(
          managerId: managerId,
          projectId: projectId,
        );
        lastUploadedBatch.value = batch;

        if (batch != null) {
          final unassigned =
              await _leadService.getUnassignedLeadsFromBatch(batch.id);
          unassignedCount.value = unassigned.length;
        } else {
          unassignedCount.value = 0;
        }

        // Fetch dashboard stats FOR THIS PROJECT
        final stats = await _leadService.getProjectDashboardStats(
          managerId: managerId,
          projectId: projectId,
        );
        totalLeads.value = stats['totalLeads'] as int;
        final assignedCount = stats['assignedLeads'] as int;
        if (totalLeads.value > 0) {
          leadsAssigned.value =
              ((assignedCount / totalLeads.value) * 100).toInt();
        } else {
          leadsAssigned.value = 0;
        }

        teamPerformance.value =
            (stats['performance'] as num).toDouble().toPrecision(1);

        // Team stats (still manager-wide, not project-filtered)
        final team = await _leadService.getManagerTeamStats(managerId);
        if (team.isNotEmpty) {
          teamMembers.value = team;
        }

        // Last call activity
        try {
          final lastCall =
              await _leadService.getLastCallByManager(managerId);
          lastCallLog.value = lastCall;
        } catch (e) {
          print('Error fetching last call: $e');
        }

        // Weekly distribution
        try {
          final weeklyData =
              await _leadService.getWeeklyDistribution(managerId);
          if (weeklyData.isNotEmpty) {
            weeklyDistribution.value = weeklyData;
          }
        } catch (e) {
          print('Error fetching weekly distribution: $e');
        }
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
