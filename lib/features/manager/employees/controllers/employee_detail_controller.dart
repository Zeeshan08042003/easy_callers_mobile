import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/employee/models/call_log_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
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
      final newOtp = await _authService.resendEmployeeOTP(employee.value!.email);
      
      if (newOtp != null) {
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('OTP Sent via Email', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A new activation code has been sent via email to',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                Text(
                  employee.value!.fullName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  employee.value!.email,
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                  'This code has been emailed and is valid for 24 hours.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
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

  // ============================================
  // UPDATE EMPLOYEE DETAILS
  // ============================================

  // Edit form controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final RxBool isUpdating = false.obs;

  /// Populate the edit form with current employee data
  void populateEditForm() {
    final emp = employee.value;
    if (emp == null) return;
    firstNameController.text = emp.firstName;
    lastNameController.text = emp.lastName;
    phoneController.text = emp.phone ?? '';
    emailController.text = emp.email;
  }

  /// Update employee details in the database
  Future<bool> updateEmployee() async {
    if (employee.value == null) return false;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      Get.snackbar('Required', 'First name and last name are required');
      return false;
    }

    try {
      isUpdating.value = true;

      final updateData = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'phone': phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
      };

      // If email changed, validate newness
      final newEmail = emailController.text.trim().toLowerCase();
      if (newEmail.isNotEmpty && newEmail != employee.value!.email.toLowerCase()) {
        updateData['email'] = newEmail;
      }

      final supabase = Get.find<SupabaseService>();
      await supabase.employeesTable
          .update(updateData)
          .eq('id', employee.value!.id);

      // Refresh the employee data from the DB
      await _refreshEmployee();

      Get.snackbar('Success', 'Employee details updated');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update employee: $e');
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Re-fetch the employee from the database
  Future<void> _refreshEmployee() async {
    if (employee.value == null) return;

    try {
      final supabase = Get.find<SupabaseService>();
      final data = await supabase.employeesTable
          .select()
          .eq('id', employee.value!.id)
          .single();

      employee.value = EmployeeModel.fromJson(data);
    } catch (e) {
      print('Error refreshing employee: $e');
    }
  }

  /// Toggle employee active status
  Future<void> toggleActiveStatus() async {
    if (employee.value == null) return;

    try {
      isUpdating.value = true;
      final newStatus = !employee.value!.isActive;

      final supabase = Get.find<SupabaseService>();
      await supabase.employeesTable
          .update({'is_active': newStatus})
          .eq('id', employee.value!.id);

      await _refreshEmployee();
      Get.snackbar(
        'Success',
        newStatus ? 'Employee activated' : 'Employee deactivated',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
