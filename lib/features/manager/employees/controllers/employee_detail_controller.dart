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

  // Pagination state for assigned leads
  static const int _pageSize = 20;
  int _currentPage = 1;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreLeads = true.obs;
  final RxInt totalLeadsCount = 0.obs;

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

      // Reset pagination state
      _currentPage = 1;
      assignedLeads.clear();
      hasMoreLeads.value = true;

      // Fetch in parallel: first page of leads + stats + other data
      final results = await Future.wait([
        _leadService.getCallLogsByEmployee(empId, limit: 1),
        _leadService.getLeadsByEmployee(empId, page: 1, pageSize: _pageSize),
        _leadService.getEmployeeStats(empId),
        if (managerId != null) _leadService.getUnattendedLeadsCount(managerId),
      ]);

      recentCalls.value = results[0] as List<CallLogModel>;

      final firstPageLeads = results[1] as List<LeadModel>;
      assignedLeads.value = firstPageLeads;

      stats.value = results[2] as Map<String, dynamic>;

      // Get total count from stats (already fetched by getEmployeeStats)
      totalLeadsCount.value = (stats['total_leads'] as int?) ?? 0;

      // Check if there are more leads to load
      hasMoreLeads.value = firstPageLeads.length >= _pageSize;

      if (managerId != null && results.length > 3) {
        unattendedLeadsCount.value = results[3] as int;
      }

    } catch (e) {
      Get.snackbar('Error', 'Failed to load performance data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more leads (next page)
  Future<void> loadMoreLeads() async {
    if (employee.value == null || isLoadingMore.value || !hasMoreLeads.value) return;

    try {
      isLoadingMore.value = true;
      _currentPage++;

      final moreLeads = await _leadService.getLeadsByEmployee(
        employee.value!.id,
        page: _currentPage,
        pageSize: _pageSize,
      );

      assignedLeads.addAll(moreLeads);

      // If we got fewer leads than the page size, there are no more to load
      hasMoreLeads.value = moreLeads.length >= _pageSize;
    } catch (e) {
      _currentPage--; // Revert page on error
      Get.snackbar('Error', 'Failed to load more leads: $e');
    } finally {
      isLoadingMore.value = false;
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
      final success = await _authService.requestActivationOTP(employee.value!.email);
      
      if (success) {
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('OTP Sent', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A new activation code has been sent directly to',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  employee.value!.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  employee.value!.email,
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Icon(Icons.mark_email_read_rounded, color: AppColors.primary, size: 48),
                const SizedBox(height: 20),
                const Text(
                  'The employee can use the code from their email to activate.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Got it', style: TextStyle(color: AppColors.primary)),
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
