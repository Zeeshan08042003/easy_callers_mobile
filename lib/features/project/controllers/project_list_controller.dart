import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/project/models/project_member_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';

import '../../../core/theme/app_colors.dart';

/// Controller for the project list view.
/// Handles fetching, searching, and filtering projects.
class ProjectListController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<ProjectModel> filteredProjects = <ProjectModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Pending invitations count (for badge)
  final RxInt pendingInvitationCount = 0.obs;
  final RxList<ProjectMemberModel> pendingInvitations = <ProjectMemberModel>[].obs;
  
  // Optional manager ID for Super Admin oversight
  String? oversightManagerId;

  // Debounce: avoid rapid refetching when tab switches quickly
  DateTime? _lastRefresh;

  // Real-time subscription for project membership changes
  StreamSubscription? _membershipSubscription;

  /// Called by the view every time it becomes visible (tab switch).
  /// Only re-fetches if at least 3 seconds have passed since the last fetch.
  void refreshIfNeeded() {
    final now = DateTime.now();
    if (_lastRefresh == null || now.difference(_lastRefresh!).inSeconds >= 3) {
      _lastRefresh = now;
      fetchProjects();
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Check for oversight mode
    if (Get.arguments is String) {
      oversightManagerId = Get.arguments as String;
    } else if (Get.arguments is ManagerModel) {
      oversightManagerId = (Get.arguments as ManagerModel).id;
    }

    fetchProjects();
    if (_authService.currentRole.value == UserRole.manager || 
        _authService.currentRole.value == UserRole.agency || 
        oversightManagerId != null) {
      fetchPendingInvitations();
      _startMembershipListener();
    }
  }

  @override
  void onClose() {
    _membershipSubscription?.cancel();
    super.onClose();
  }

  /// Listen for real-time changes to project_members for this manager.
  /// When SA removes manager from a project, the manager's dashboard
  /// and project list will auto-refresh.
  void _startMembershipListener() {
    final mgrId = oversightManagerId ?? _authService.currentManager.value?.id;
    if (mgrId == null) return;

    _membershipSubscription?.cancel();
    _membershipSubscription = Get.find<SupabaseService>()
        .client
        .from('project_members')
        .stream(primaryKey: ['id'])
        .eq('manager_id', mgrId)
        .listen((List<Map<String, dynamic>> data) {
          // Compare current project count with stream data
          // If a membership was deleted (fewer rows), refresh
          final acceptedCount = data.where((d) => d['status'] == 'accepted').length;
          if (projects.isNotEmpty && acceptedCount < projects.length) {
            // A project was removed — refresh everything
            print('🔄 Real-time: detected membership change, refreshing...');
            fetchProjects();
            
            // Also refresh dashboard if registered
            if (Get.isRegistered<ManagerDashboardController>()) {
              Get.find<ManagerDashboardController>().fetchProjects();
            }
          } else if (acceptedCount > projects.length) {
            // A new project was added — refresh
            fetchProjects();
          }
        });
  }

  Future<void> fetchProjects() async {
    try {
      isLoading.value = true;

      final role = _authService.currentRole.value;

      if (oversightManagerId != null) {
        // Oversight mode: fetch projects for the targeted manager
        projects.value = await _projectService.getProjectsForManager(oversightManagerId!);
      } else if (role == UserRole.superAdmin) {
        final saId = _authService.currentSuperAdmin.value?.id;
        if (saId == null) return;
        projects.value = await _projectService.getProjectsForSuperAdmin(saId);
      } else if (role == UserRole.manager || role == UserRole.agency) {
        final mgrId = _authService.currentManager.value?.id;
        if (mgrId == null) return;
        projects.value = await _projectService.getProjectsForManager(mgrId);
      }

      _applySearch();

      // Also refresh pending invitations for managers
      if (role == UserRole.manager || role == UserRole.agency || oversightManagerId != null) {
        fetchPendingInvitations();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load projects: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPendingInvitations() async {
    try {
      final mgrId = oversightManagerId ?? _authService.currentManager.value?.id;
      final role = _authService.currentRole.value;
      print('=== fetchPendingInvitations ===');
      print('Role: $role');
      print('Manager ID: $mgrId');
      print('Current Manager: ${_authService.currentManager.value}');
      
      if (mgrId == null) {
        print('❌ Manager ID is null, skipping invitation fetch');
        return;
      }

      final results = await _projectService.getPendingInvitations(mgrId);
      print('✅ Got ${results.length} pending invitations');
      pendingInvitations.value = results;
      pendingInvitationCount.value = results.length;
    } catch (e) {
      print('❌ Error fetching pending invitations: $e');
    }
  }

  Future<void> acceptInvitation(ProjectMemberModel invitation) async {
    try {
      final success = await _projectService.acceptInvitation(invitation.id);
      if (success) {
        Get.snackbar('Success', 'Invitation accepted! You are now a member of "${invitation.projectName}"');
        await fetchPendingInvitations();
        await fetchProjects();

        // Also refresh the dashboard controller so the new project
        // appears in the project selector immediately
        if (Get.isRegistered<ManagerDashboardController>()) {
          Get.find<ManagerDashboardController>().refreshAfterInvitation();
        }

        // Prompt manager to select callers for the project
        final managerId = _authService.currentManager.value?.id;
        if (managerId != null) {
          await _showCallerSelectionDialog(
            projectId: invitation.projectId,
            projectName: invitation.projectName ?? 'Project',
            managerId: managerId,
          );
        }
      } else {
        Get.snackbar('Error', 'Failed to accept invitation. Please try again.',
            backgroundColor: AppColors.danger.withOpacity(0.1),
            colorText: AppColors.danger);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation: $e');
    }
  }

  /// Show a dialog allowing the manager to select which callers to add to the project.
  /// Features a "Select All" toggle and individual checkboxes.
  Future<void> _showCallerSelectionDialog({
    required String projectId,
    required String projectName,
    required String managerId,
  }) async {
    // Fetch all employees under this manager
    final leadService = Get.find<LeadService>();
    final allEmployees = await leadService.getEmployeesByManager(managerId);
    final activeEmployees = allEmployees.where((e) => e.isActive).toList();

    if (activeEmployees.isEmpty) {
      Get.snackbar(
        'No Active Callers',
        'You don\'t have any active callers yet. Add callers from the project settings later.',
        duration: const Duration(seconds: 4),
      );
      // Still check for unassigned leads
      _checkAndPromptRedistribution(projectId, projectName);
      return;
    }

    // Track selections — default: all selected
    final selected = <String, bool>{}.obs;
    for (final emp in activeEmployees) {
      selected[emp.id] = true;
    }
    final selectAll = true.obs;
    final isAdding = false.obs;

    await Get.dialog(
      PopScope(
        canPop: false, // Force user to make a choice
        child: AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Callers to Project',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select callers to add to "$projectName"',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Select All toggle
                Obx(() => InkWell(
                  onTap: () {
                    final newVal = !selectAll.value;
                    selectAll.value = newVal;
                    for (final emp in activeEmployees) {
                      selected[emp.id] = newVal;
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: selectAll.value
                          ? AppColors.primary.withOpacity(0.08)
                          : Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectAll.value
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectAll.value
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: selectAll.value
                              ? AppColors.primary
                              : Colors.white38,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Select All (${activeEmployees.length})',
                          style: TextStyle(
                            color: selectAll.value ? AppColors.primary : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 12),
                // Employee list
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(Get.context!).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: activeEmployees.length,
                    itemBuilder: (context, index) {
                      final emp = activeEmployees[index];
                      return Obx(() => InkWell(
                        onTap: () {
                          selected[emp.id] = !(selected[emp.id] ?? false);
                          // Update selectAll
                          selectAll.value = activeEmployees.every((e) => selected[e.id] == true);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                (selected[emp.id] ?? false)
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: (selected[emp.id] ?? false)
                                    ? AppColors.success
                                    : Colors.white24,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withOpacity(0.12),
                                child: Text(
                                  emp.initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emp.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      emp.email,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Skip', style: TextStyle(color: Colors.white54)),
            ),
            Obx(() => ElevatedButton(
              onPressed: isAdding.value
                  ? null
                  : () async {
                      final selectedIds = selected.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();

                      if (selectedIds.isEmpty) {
                        Get.snackbar('No Selection', 'Please select at least one caller or tap Skip.');
                        return;
                      }

                      isAdding.value = true;
                      final success = await _projectService.addCallersToProject(
                        projectId: projectId,
                        employeeIds: selectedIds,
                        managerId: managerId,
                      );
                      isAdding.value = false;

                      if (success) {
                        Get.back();
                        Get.snackbar(
                          'Done',
                          '${selectedIds.length} caller${selectedIds.length != 1 ? 's' : ''} added to "$projectName"',
                        );
                        // Now check for unassigned leads
                        _checkAndPromptRedistribution(projectId, projectName);
                      } else {
                        Get.snackbar('Error', 'Failed to add callers. Try adding them from project settings.');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: isAdding.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Obx(() {
                      final count = selected.values.where((v) => v).length;
                      return Text(
                        count == activeEmployees.length
                            ? 'Add All ($count)'
                            : 'Add Selected ($count)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      );
                    }),
            )),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Check if the project has unassigned leads and prompt for redistribution
  Future<void> _checkAndPromptRedistribution(String projectId, String? projectName) async {
    try {
      final leadService = Get.find<LeadService>();
      final unassignedLeads = await leadService.getUnassignedLeadsForProject(projectId);
      
      if (unassignedLeads.isNotEmpty) {
        // Wait a moment so the previous snackbar is visible
        await Future.delayed(const Duration(milliseconds: 800));
        
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Leads Need Distribution',
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
                      const TextSpan(text: 'Project '),
                      TextSpan(
                        text: '"${projectName ?? 'Unnamed'}"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' has ${unassignedLeads.length} unassigned lead${unassignedLeads.length != 1 ? 's' : ''}.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Would you like to distribute these leads to your team now?',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Later', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  // Navigate to the dashboard and select this project for distribution
                  if (Get.isRegistered<ManagerDashboardController>()) {
                    final dashCtrl = Get.find<ManagerDashboardController>();
                    final project = dashCtrl.projects.firstWhereOrNull((p) => p.id == projectId);
                    if (project != null) {
                      dashCtrl.selectProject(project);
                      dashCtrl.switchTab(0); // Switch to dashboard
                      // Trigger the distribute flow after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        dashCtrl.distributeLeads();
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Distribute Now'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('⚠️ Could not check for unassigned leads: $e');
    }
  }

  Future<void> declineInvitation(ProjectMemberModel invitation) async {
    try {
      final success = await _projectService.declineInvitation(invitation.id);
      if (success) {
        Get.snackbar('Done', 'Invitation declined');
        await fetchPendingInvitations();
      } else {
        Get.snackbar('Error', 'Failed to decline invitation. Please try again.',
            backgroundColor: AppColors.danger.withOpacity(0.1),
            colorText: AppColors.danger);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation: $e');
    }
  }

  void searchProjects(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    if (searchQuery.value.isEmpty) {
      filteredProjects.value = projects.toList();
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredProjects.value = projects.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.subtitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  bool get isSuperAdmin => _authService.currentRole.value == UserRole.superAdmin && oversightManagerId == null;
  bool get isManager => _authService.currentRole.value == UserRole.manager || 
                     _authService.currentRole.value == UserRole.agency || 
                     oversightManagerId != null;
}
