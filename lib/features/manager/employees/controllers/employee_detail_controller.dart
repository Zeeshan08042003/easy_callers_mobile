import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/theme/app_colors.dart';

class EmployeeDetailController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<EmployeeModel?> employee = Rx<EmployeeModel?>(null);
  final RxList<CallLogModel> recentCalls = <CallLogModel>[].obs;
  final RxList<LeadModel> assignedLeads = <LeadModel>[].obs;
  final RxMap<String, dynamic> stats = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;
  final RxInt unattendedLeadsCount = 0.obs;
  final RxBool isReassigning = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is EmployeeModel) {
      employee.value = Get.arguments as EmployeeModel;
      fetchData();
    }
  }

  Future<void> fetchData() async {
    if (employee.value == null) return;

    try {
      isLoading.value = true;
      final empId = employee.value!.id;
      final managerId = _authService.currentManager.value?.id;

      // Fetch in parallel
      final results = await Future.wait([
        _leadService.getCallLogsByEmployee(empId, limit: 1),
        _leadService.getLeadsByEmployee(empId),
        _leadService.getEmployeeStats(empId),
        if (managerId != null) _leadService.getUnattendedLeadsCount(managerId),
      ]);

      recentCalls.value = results[0] as List<CallLogModel>;
      assignedLeads.value = (results[1] as List<LeadModel>).reversed.take(5).toList();
      stats.value = results[2] as Map<String, dynamic>;
      
      if (managerId != null && results.length > 3) {
        unattendedLeadsCount.value = results[3] as int;
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to load performance data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reassignUnattendedLeads() async {
    if (employee.value == null) return;
    
    final managerId = _authService.currentManager.value?.id;
    if (managerId == null) {
      Get.snackbar('Error', 'Manager ID not found');
      return;
    }

    // Check if employee is active
    if (!employee.value!.isActive) {
      Get.snackbar(
        'Cannot Reassign',
        'Employee must be active to receive leads',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isReassigning.value = true;

      final count = await _leadService.reassignUnattendedLeadsToEmployee(
        managerId: managerId,
        targetEmployeeId: employee.value!.id,
      );

      if (count > 0) {
        Get.snackbar(
          'Success',
          'Reassigned $count unattended lead${count != 1 ? 's' : ''} to ${employee.value!.firstName}',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        // Refresh data
        await fetchData();
      } else {
        Get.snackbar(
          'No Leads Available',
          'There are no unattended leads to reassign',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to reassign leads: $e');
    } finally {
      isReassigning.value = false;
    }
  }

  Future<void> resendOTP() async {
    if (employee.value == null) return;
    
    try {
      isLoading.value = true;
      final newOtp = await _authService.resendEmployeeOTP(employee.value!.email);
      
      if (newOtp != null) {
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('New OTP Generated', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A new activation code has been generated for',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  employee.value!.fullName,
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
        await fetchData(); // Refresh
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend OTP: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
