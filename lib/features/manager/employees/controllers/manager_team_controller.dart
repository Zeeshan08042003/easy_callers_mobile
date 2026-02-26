import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';

class ManagerTeamController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxBool isLoading = false.obs;

  // Optional manager ID for Super Admin oversight
  String? oversightManagerId;

  // Add Employee State
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final RxBool isCreating = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Check for oversight mode
    if (Get.arguments is String) {
      oversightManagerId = Get.arguments as String;
    } else if (Get.arguments is ManagerModel) {
      oversightManagerId = (Get.arguments as ManagerModel).id;
    }

    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      isLoading.value = true;
      final managerId =
          oversightManagerId ?? _authService.currentManager.value?.id;
      if (managerId == null) return;

      final result = await _leadService.getEmployeesByManager(managerId);
      employees.value = result;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch team: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createEmployee() async {
    if (!_validateFields()) return;

    try {
      isCreating.value = true;
      final result = await _authService.createEmployee(
        email: emailController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      );

      if (result != null) {
        fetchEmployees(); // Refresh list
        Get.snackbar('Success',
            'Employee created. An activation email has been sent to them.');
        _clearFields();
      } else {
        Get.snackbar('Error', _authService.error.value);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to create employee: $e');
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> resendOTP(EmployeeModel employee) async {
    try {
      isLoading.value = true;
      final success = await _authService.requestActivationOTP(employee.email);

      if (success) {
        // Show success
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title:
                const Text('OTP Sent', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A new activation code has been sent directly to',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  employee.fullName,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  employee.email,
                  style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.mark_email_read_rounded,
                    color: AppColors.primary, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'The employee can use the code from their email to activate.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Got it',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
        fetchEmployees(); // Refresh list
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend OTP: $e');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateFields() {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty) {
      Get.snackbar('Required', 'First name, last name, and email are required');
      return false;
    }
    return true;
  }

  void _clearFields() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
