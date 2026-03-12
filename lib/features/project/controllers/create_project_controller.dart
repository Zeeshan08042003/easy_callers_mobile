import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/super_admin/dashboard/controllers/super_admin_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

/// Controller for creating a new project.
class CreateProjectController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final WebService _webService = Get.find<WebService>();
  final AuthService _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final subtitleController = TextEditingController();
  final instructionController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool visibleToSuperAdmin = false.obs;
  final RxString callerAssignment = 'all'.obs; // 'all' or 'selected'

  // Employee (caller) selection
  final RxList<EmployeeModel> allEmployees = <EmployeeModel>[].obs;
  final RxSet<String> selectedEmployeeIds = <String>{}.obs;
  final RxBool isLoadingEmployees = false.obs;

  // Manager selection (for Super Admin)
  final RxList<ManagerModel> allManagers = <ManagerModel>[].obs;
  final RxSet<String> selectedManagerIds = <String>{}.obs;
  final RxBool isLoadingManagers = false.obs;
  final RxString managerAssignment = 'my_managers'.obs; // 'my_managers' or 'agencies'

  @override
  void onInit() {
    super.onInit();
    if (isManager) {
      fetchEmployees();
      fetchManagers(); // Also fetch agencies for collaboration
    } else if (isSuperAdmin) {
      fetchManagers();
    }
  }

  /// Fetch managers (agencies for Manager, internal for Super Admin)
  Future<void> fetchManagers() async {
    try {
      isLoadingManagers.value = true;
      final saId = _authService.currentSuperAdmin.value?.id;
      final currentManagerId = _authService.currentManager.value?.id;
      
      // If SA: get their created managers + agencies
      // If Manager (Agency): get agencies
      final managersStr = (await _webService.getAllManagersAndAgencies(currentSuperAdminId: saId)).payload ?? [];
      
      // Filter out the current user themselves
      allManagers.assignAll(
        managersStr.where((m) => m.id != currentManagerId).toList()
      );

      // Default auto-selection for SA
      if (isSuperAdmin && managerAssignment.value == 'my_managers') {
        setManagerAssignment('my_managers');
      }
    } catch (e) {
      print('Error fetching managers: $e');
    } finally {
      isLoadingManagers.value = false;
    }
  }

  /// Set assignment mode and handle auto-selection
  void setManagerAssignment(String mode) {
    managerAssignment.value = mode;
    final saId = _authService.currentSuperAdmin.value?.id;
    
    if (mode == 'my_managers') {
      // Auto-select all SA's managers
      final myIds = allManagers
          .where((m) => m.createdBySuperAdminId == saId)
          .map((m) => m.id)
          .toSet();
      selectedManagerIds.assignAll(myIds);
    } else if (mode == 'agencies') {
      // For agencies mode, if we want to allow fresh selection
      // we could clear, or just leave it. User said "can select agencies".
      // I'll leave existing for now but UI will filter.
    } else if (mode == 'all') {
      // Auto-select everything
      selectedManagerIds.assignAll(allManagers.map((m) => m.id).toSet());
    }
  }

  /// Get managers filtered by the current assignment mode
  List<ManagerModel> get filteredManagers {
    final saId = _authService.currentSuperAdmin.value?.id;
    if (managerAssignment.value == 'my_managers') {
      return allManagers.where((m) => m.createdBySuperAdminId == saId).toList();
    } else if (managerAssignment.value == 'agencies') {
      return allManagers.where((m) => m.createdBySuperAdminId == null).toList();
    }
    return allManagers;
  }

  /// Toggle selection of a manager
  void toggleManager(String managerId) {
    if (selectedManagerIds.contains(managerId)) {
      selectedManagerIds.remove(managerId);
    } else {
      selectedManagerIds.add(managerId);
    }
  }

  /// Fetch the manager's employees
  Future<void> fetchEmployees() async {
    try {
      isLoadingEmployees.value = true;
      final mgrId = _authService.currentManager.value?.id;
      if (mgrId == null) return;

      final employeesStr = (await _webService.getEmployeesByManager(mgrId)).payload ?? [];
      allEmployees.value = employeesStr.where((e) => e.isActive).toList();
    } catch (e) {
      print('Error fetching employees: $e');
    } finally {
      isLoadingEmployees.value = false;
    }
  }

  /// Toggle selection of an employee
  void toggleEmployee(String employeeId) {
    if (selectedEmployeeIds.contains(employeeId)) {
      selectedEmployeeIds.remove(employeeId);
    } else {
      selectedEmployeeIds.add(employeeId);
    }
  }

  /// Select all managers
  void selectAllManagers() {
    selectedManagerIds.assignAll(allManagers.map((m) => m.id).toSet());
  }

  /// Deselect all managers
  void deselectAllManagers() {
    selectedManagerIds.clear();
  }

  /// Select all employees
  void selectAllEmployees() {
    selectedEmployeeIds.assignAll(allEmployees.map((e) => e.id).toSet());
  }

  /// Deselect all employees
  void deselectAllEmployees() {
    selectedEmployeeIds.clear();
  }

  void _showSafeSnackbar(String title, String message, {bool isError = false}) {
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('$title: $message', style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      Get.snackbar(title, message);
    }
  }

  void _safePop(dynamic result) {
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx != null) {
      Navigator.of(ctx).pop(result);
    } else {
      Get.back(result: result);
    }
  }

  Future<void> createProject() async {
    // Validate name
    if (nameController.text.trim().isEmpty) {
      _showSafeSnackbar('Required', 'Please enter a project name', isError: true);
      return;
    }

    // Validate selected callers (Manager only)
    if (isManager && callerAssignment.value == 'selected' &&
        selectedEmployeeIds.isEmpty) {
      _showSafeSnackbar(
        'Required',
        'Please select at least one caller',
        isError: true,
      );
      return;
    }

    // Validate selected managers (Super Admin only)
    if (isSuperAdmin && managerAssignment.value == 'selected' &&
        selectedManagerIds.isEmpty) {
      _showSafeSnackbar(
        'Required',
        'Please select at least one manager',
        isError: true,
      );
      return;
    }

    try {
      isLoading.value = true;

      final role = _authService.currentRole.value;

      final subtitleText = subtitleController.text.trim().isEmpty
          ? null
          : subtitleController.text.trim();

      final instructionText = instructionController.text.trim().isEmpty
          ? null
          : instructionController.text.trim();

      dynamic project;

      // ==============================
      // SUPER ADMIN
      // ==============================
      if (role == UserRole.superAdmin) {
        final saId = _authService.currentSuperAdmin.value?.id;

        if (saId == null) {
          _showSafeSnackbar(
            'Error',
            'Super Admin profile not found',
            isError: true,
          );
          return;
        }

        project = await _projectService.createProjectAsSuperAdmin(
          name: nameController.text.trim(),
          subtitle: subtitleText,
          instruction: instructionText,
          superAdminId: saId,
          callerAssignment: 'all', // Super Admin doesn't manage specific callers
        );

        if (project != null) {
          List<ManagerModel> targetManagers;
          
          // Use the selectedManagerIds filtered to the mode's scope
          final saId = _authService.currentSuperAdmin.value?.id;
          targetManagers = allManagers.where((m) {
            if (!selectedManagerIds.contains(m.id)) return false;
            
            if (managerAssignment.value == 'my_managers') {
              return m.createdBySuperAdminId == saId;
            } else if (managerAssignment.value == 'agencies') {
              return m.createdBySuperAdminId == null;
            }
            return true;
          }).toList();

          for (final manager in targetManagers) {
            await _projectService.inviteManagerToProject(
              projectId: project.id,
              managerId: manager.id,
              superAdminId: saId,
            );
          }
        }
      }

      // ==============================
      // MANAGER & AGENCY
      // ==============================
      else if (role == UserRole.manager || role == UserRole.agency) {
        final mgrId = _authService.currentManager.value?.id;

        if (mgrId == null) {
          _showSafeSnackbar(
            'Error',
            'Manager profile not found',
            isError: true,
          );
          return;
        }

        project = await _projectService.createProjectAsManager(
          name: nameController.text.trim(),
          subtitle: subtitleText,
          instruction: instructionText,
          managerId: mgrId,
          visibleToSuperAdmin: visibleToSuperAdmin.value,
          callerAssignment: callerAssignment.value,
        );

        if (project != null) {
          if (callerAssignment.value == 'selected') {
            for (final empId in selectedEmployeeIds) {
              await _projectService.addCallerToProject(
                projectId: project.id,
                employeeId: empId,
                managerId: mgrId,
              );
            }
          } else {
            await _projectService.addAllCallersToProject(
              projectId: project.id,
              managerId: mgrId,
            );
          }
        }
      }

      // ==============================
      // SUCCESS
      // ==============================
      if (project != null) {
        try {
          Get.find<ManagerDashboardController>().fetchProjects();
        } catch (_) {}
        try {
          Get.find<SuperAdminDashboardController>().refreshDashboard();
        } catch (_) {}

        FocusManager.instance.primaryFocus?.unfocus();

        final ctx = Get.overlayContext ?? Get.context;

        if (ctx != null && Navigator.of(ctx).canPop()) {
          Navigator.of(ctx).pop(project);
        }
      }
    } catch (e) {
      _showSafeSnackbar(
        'Error',
        'Failed to create project: $e',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }


  bool get isManager => _authService.currentRole.value == UserRole.manager || 
                     _authService.currentRole.value == UserRole.agency;
  bool get isSuperAdmin => _authService.currentRole.value == UserRole.superAdmin;

  @override
  void onClose() {
    nameController.dispose();
    subtitleController.dispose();
    instructionController.dispose();
    super.onClose();
  }
}
