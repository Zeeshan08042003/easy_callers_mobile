import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/storage_service.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/services/background_upload_manager.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';

import '../../../employee/models/call_log_model.dart';
import '../../leads/bindings/distribute_leads_binding.dart';
import '../../leads/views/distribute_leads_view.dart';
import '../../models/lead_model.dart';

class ManagerDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();
  
  // Optional manager ID for Super Admin oversight
  String? oversightManagerId;
  
  String? get currentManagerId => oversightManagerId ?? _authService.currentManager.value?.id;
  
  // ============================================
  // NAVIGATION
  // ============================================
  final RxInt currentTabIndex = 0.obs;
  
  void switchTab(int index) {
    currentTabIndex.value = index;
    // Refresh project list when switching back to dashboard home
    // to pick up any changes (e.g., SA removed manager from project)
    if (index == 0) {
      fetchProjects();
    }
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
  
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool canUploadExcel = true.obs; // This should be fetched properly
  
  // Status Counts
  final dailyFollowUps = 0.obs;
  final dailyVisiting = 0.obs;
  final visitCompleted = 0.obs;
  final convertedCount = 0.obs;
  final allActivityCount = 0.obs;

  final Rx<LeadBatchModel?> lastUploadedBatch = Rx<LeadBatchModel?>(null);
  final unassignedCount = 0.obs;

  // Team members list
  final teamMembers = <Map<String, dynamic>>[].obs;

  // Weekly distribution data (M, T, W, T, F, S)
  final weeklyDistribution = <double>[0.5, 0.7, 0.4, 1.0, 0.8, 0.3].obs;

  // Lead lifecycle list on dashboard home
  final dashboardLeads = <LeadModel>[].obs;
  final isLoadingLeads = false.obs;
  final selectedLifecycleTab = 0.obs; // 0: Follow-up, 1: Visiting, 2: Completed, 3: All

  // Last call activity across all team members
  final Rx<CallLogModel?> lastCallLog = Rx<CallLogModel?>(null);

  // Permissions

  // Real-time subscription for project membership changes
  StreamSubscription? _membershipSubscription;

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
      // Start real-time listener for membership changes
      _startMembershipListener();
    }
  }

  @override
  void onClose() {
    _membershipSubscription?.cancel();
    super.onClose();
  }

  /// Listen for real-time changes to project_members for this manager.
  /// When SA removes manager from a project, dashboard auto-refreshes.
  void _startMembershipListener() {
    final mgrId = currentManagerId;
    if (mgrId == null) return;

    _membershipSubscription?.cancel();
    _membershipSubscription = Get.find<SupabaseService>()
        .client
        .from('project_members')
        .stream(primaryKey: ['id'])
        .eq('manager_id', mgrId)
        .listen((List<Map<String, dynamic>> data) {
          final acceptedCount = data.where((d) => d['status'] == 'accepted').length;
          if (projects.isNotEmpty && acceptedCount != projects.length) {
            print('🔄 Dashboard: real-time membership change detected, refreshing...');
            fetchProjects();
          }
        });
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
        //    (will be null if the selected project was removed from manager's access)
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

        // If previously selected project is no longer accessible (removed by SA),
        // clear stale saved project IDs so we don't try to reselect it next time
        if (selectedProject.value != null && 
            !result.any((p) => p.id == selectedProject.value!.id)) {
          _storage.setString('last_project_id_$managerId', toSelect.id);
          _storage.setString(StorageService.keyLastProjectID, toSelect.id);
        }

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
    dailyFollowUps.value = 0;
    dailyVisiting.value = 0;
    visitCompleted.value = 0;
    convertedCount.value = 0;
    allActivityCount.value = 0;
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

    if (!canUploadExcel.value) {
      Get.snackbar(
        'Permission Denied', 
        'The Super Admin has not granted you permission to upload leads to this project.',
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }

    final managerId = _authService.currentManager.value?.id;
    final superAdminId = _authService.currentSuperAdmin.value?.id;

    if (managerId == null && superAdminId == null) {
      Get.snackbar('Error', 'Profile not found');
      return;
    }

    try {
      isUploading.value = true;
      
      // Use background upload manager — file picker opens immediately,
      // upload runs in background so the user can keep using the app.
      final uploadManager = Get.find<BackgroundUploadManager>();
      await uploadManager.startUpload(
        managerId: managerId,
        projectId: selectedProject.value!.id,
        projectName: selectedProject.value!.name,
      );

      // Refresh dashboard data after a short delay to pick up new batch
      Future.delayed(const Duration(seconds: 2), () {
        fetchDashboardData();
      });
    } catch (e) {
      print('Error starting upload: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> distributeLeads() async {
    if (selectedProject.value == null || unassignedCount.value == 0) {
      Get.snackbar('Error', 'No unassigned leads to distribute');
      return;
    }

    try {
      isLoading.value = true;

      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) {
        Get.snackbar('Error', 'Manager profile not found');
        return;
      }

      final employees = await _leadService.getEmployeesByManager(managerId);

      if (employees.isEmpty) {
        isLoading.value = false;
        Get.snackbar(
          'No Employees Found',
          'Please add employees first before distributing leads',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isLoading.value = false;

      // Pass project info so distribution works with ALL unassigned leads
      // across all batches in this project
      await Get.to(
        () => const DistributeLeadsView(),
        binding: DistributeLeadsBinding(),
        arguments: {
          'projectId': selectedProject.value!.id,
          'projectName': selectedProject.value!.name,
          'totalUnassigned': unassignedCount.value,
          'managerId': managerId,
          // Also pass a batch if one exists, for backward compatibility
          if (lastUploadedBatch.value != null) 'batch': lastUploadedBatch.value,
        },
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

  /// Called from ProjectListController after accepting an invitation
  /// to immediately refresh the dashboard project list
  void refreshAfterInvitation() {
    fetchProjects();
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
        // Fetch permissions for this project
        final membership = await _projectService.getMyMembershipForProject(
          projectId: projectId,
          managerId: managerId,
        );
        
        // If owner, always allowed. If member, check can_upload flag.
        // Super admin oversight always has permission.
        if (oversightManagerId != null || _authService.currentSuperAdmin.value != null) {
          canUploadExcel.value = true;
        } else if (membership != null) {
          if (membership.isOwner) {
            canUploadExcel.value = true;
          } else {
            canUploadExcel.value = membership.canUpload;
          }
        } else {
          canUploadExcel.value = false; // Default to false if membership not found
        }

        // Fetch latest batch (for reference)
        final batch = await _leadService.getLatestBatchWithUnassignedLeadsForProject(
          managerId: oversightManagerId,
          projectId: projectId,
        );
        lastUploadedBatch.value = batch;

        // Count ALL unassigned leads across ALL batches in the project
        final allUnassigned = await _leadService.getUnassignedLeadsForProject(projectId);
        unassignedCount.value = allUnassigned.length;

        // Fetch dashboard stats FOR THIS PROJECT
        final stats = await _leadService.getProjectDashboardStats(
          managerId: managerId, // Filter stats by manager
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

        // Fetch status counts
        final statusCounts = await _leadService.getProjectStatusCounts(
          projectId: projectId,
          managerId: managerId, // Filter counts by manager
          todayOnly: true,
        );
        dailyFollowUps.value = statusCounts['follow_up'] ?? 0;
        dailyVisiting.value = statusCounts['visiting'] ?? 0;
        visitCompleted.value = statusCounts['visit_completed'] ?? 0;
        convertedCount.value = statusCounts['converted'] ?? 0;
        allActivityCount.value = statusCounts['all'] ?? 0;

        // Fetch leads for the current active tab
        await fetchDashboardLeads();

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

  void setLifecycleTab(int index) {
    selectedLifecycleTab.value = index;
    fetchDashboardLeads();
  }

  Future<void> fetchDashboardLeads() async {
    final projectId = selectedProject.value?.id;
    final managerId = oversightManagerId ?? _authService.currentManager.value?.id;
    if (projectId == null) return;

    try {
      isLoadingLeads.value = true;
      List<LeadModel> result;
      switch (selectedLifecycleTab.value) {
        case 0: // Daily Follow-ups
          result = await _leadService.getProjectLeadsByStatus(
            projectId: projectId, 
            status: 'follow_up',
            managerId: managerId,
            todayOnly: true,
          );
          break;
        case 1: // Daily Visiting
          result = await _leadService.getProjectLeadsByStatus(
            projectId: projectId, 
            status: 'visiting',
            managerId: managerId,
            todayOnly: true,
          );
          break;
        case 2: // Visit Completed
          result = await _leadService.getProjectLeadsByStatus(
            projectId: projectId, 
            status: 'visit_completed',
            managerId: managerId,
            todayOnly: true,
          );
          break;
        case 3: // All Activity
          result = await _leadService.getProjectLeads(
            projectId,
            managerId: managerId,
          );
          break;
        default:
          result = [];
          break;
      }
      dashboardLeads.assignAll(result);
    } catch (e) {
      print('Error fetching dashboard leads: $e');
    } finally {
      isLoadingLeads.value = false;
    }
  }

  Future<void> updateLeadStatus(String leadId, LeadStatus newStatus) async {
    try {
      await _leadService.updateLeadStatus(leadId, newStatus);
      
      // Remove from current dashboard list
      dashboardLeads.removeWhere((l) => l.id == leadId);
      
      // Refresh dashboard data to update counts
      await fetchDashboardData();
      
      Get.snackbar(
        'Success', 
        'Lead marked as ${newStatus.displayName}',
        backgroundColor: AppColors.success.withOpacity(0.7),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update lead status');
    }
  }
}
