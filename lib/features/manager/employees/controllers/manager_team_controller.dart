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
  
  final RxString activeOTP = ''.obs;
  final RxInt otpExpiresIn = 300.obs; // 5 minutes
  final RxBool isCreating = false.obs;
  Timer? _otpTimer;

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
      final managerId = oversightManagerId ?? _authService.currentManager.value?.id;
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
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
      );

      if (result.employee != null) {
        activeOTP.value = result.otp!;
        _startOTPTimer();
        fetchEmployees(); // Refresh list
        Get.snackbar('Success', 'Employee created. OTP has been sent to their email.');
        _clearFields(keepOTP: true);
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
      final newOtp = await _authService.resendEmployeeOTP(employee.email);
      
      if (newOtp != null) {
        // Show success with new OTP
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('OTP Sent via Email', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A new activation code has been generated and sent via email to',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  employee.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Text(
                    newOtp,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'This code is valid for 24 hours.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
        fetchEmployees(); // Refresh list to update expiry state if needed
      } else {
        Get.snackbar('Error', 'Failed to generate new OTP');
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

  void _clearFields({bool keepOTP = false}) {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    if (!keepOTP) {
      activeOTP.value = '';
      _otpTimer?.cancel();
    }
  }

  void _startOTPTimer() {
    _otpTimer?.cancel();
    otpExpiresIn.value = 86400; // Match 24 hours from AuthService
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpExpiresIn.value > 0) {
        otpExpiresIn.value--;
      } else {
        timer.cancel();
      }
    });
  }

  // Deprecated: OTP is now generated by AuthService
  void generateOTP() {}

  String get formattedTimer {
    final minutes = (otpExpiresIn.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (otpExpiresIn.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
