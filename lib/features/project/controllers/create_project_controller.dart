import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

/// Controller for creating a new project.
class CreateProjectController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final LeadService _leadService = Get.find<LeadService>();
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

  @override
  void onInit() {
    super.onInit();
    if (isManager) {
      fetchEmployees();
    }
  }

  /// Fetch the manager's employees
  Future<void> fetchEmployees() async {
    try {
      isLoadingEmployees.value = true;
      final mgrId = _authService.currentManager.value?.id;
      if (mgrId == null) return;

      final employees = await _leadService.getEmployeesByManager(mgrId);
      allEmployees.value = employees.where((e) => e.isActive).toList();
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

    // Validate selected callers
    if (callerAssignment.value == 'selected' &&
        selectedEmployeeIds.isEmpty) {
      _showSafeSnackbar(
        'Required',
        'Please select at least one caller',
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
          callerAssignment: callerAssignment.value,
        );
      }

      // ==============================
      // MANAGER
      // ==============================
      else if (role == UserRole.manager) {
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


  bool get isManager => _authService.currentRole.value == UserRole.manager;

  @override
  void onClose() {
    nameController.dispose();
    subtitleController.dispose();
    instructionController.dispose();
    super.onClose();
  }
}
