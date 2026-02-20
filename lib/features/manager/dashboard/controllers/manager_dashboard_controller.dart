import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribute_leads_binding.dart';

class ManagerDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

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

  @override
  void onInit() {
    super.onInit();
    // Fetch initial data
    fetchDashboardData();
    
    // Also listen for manager changes (e.g. after login/reboot) to ensure data loads
    ever(_authService.currentManager, (manager) {
      if (manager != null) {
        fetchDashboardData();
      }
    });
  }

  Future<void> uploadLeads() async {
    try {
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) {
        Get.snackbar('Error', 'Manager profile not found');
        return;
      }

      isLoading.value = true;
      final batch = await _leadService.pickAndUploadLeads(managerId);
      
      if (batch != null) {
        lastUploadedBatch.value = batch;
        Get.snackbar(
          'Success', 
          'Uploaded ${batch.totalLeads} leads successfully!\nClick "Distribute Leads" to assign them.',
          duration: const Duration(seconds: 4),
        );
        await fetchDashboardData();
      }
    } catch (e) {
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
      
      // Check if manager has employees
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) {
        Get.snackbar('Error', 'Manager profile not found');
        return;
      }

      print('🔍 Fetching employees for manager: $managerId');
      final employees = await _leadService.getEmployeesByManager(managerId);
      print('✅ Fetched ${employees.length} employees');
      
      if (employees.isEmpty) {
        // No employees - prompt to add employees first
        isLoading.value = false;
        Get.snackbar(
          'No Employees Found',
          'Please add employees first before distributing leads',
          duration: const Duration(seconds: 3),
        );
        
        // Navigate to employee creation/management screen
        // Uncomment when you have the employee management screen ready:
        // Get.toNamed('/manager/employees');
        return;
      }

      // Has employees - navigate to distribution screen
      isLoading.value = false;
      print('🚀 Navigating to distribution screen with batch: ${batch.id}');
      
      // Use Get.to instead of Get.toNamed to pass arguments directly
      await Get.to(
        () => const DistributeLeadsView(),
        binding: DistributeLeadsBinding(),
        arguments: batch,
      );
      
      // Refresh after returning from distribution screen
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

  Future<void> fetchDashboardData() async {
    isLoading.value = true;

    try {
      final managerId = _authService.currentManager.value?.id;

      // Fetch latest batch with unassigned leads (if any)
      if (managerId != null) {
        final batch = await _leadService.getLatestBatchWithUnassignedLeads(managerId);
        lastUploadedBatch.value = batch;

        if (batch != null) {
          final unassigned = await _leadService.getUnassignedLeadsFromBatch(batch.id);
          unassignedCount.value = unassigned.length;
        } else {
          unassignedCount.value = 0;
        }

        // Fetch real dashboard statistics
        final stats = await _leadService.getManagerDashboardStats(managerId);
        totalLeads.value = stats['totalLeads'] as int;
        print("Total value : ${totalLeads.value}");
        final assignedCount = stats['assignedLeads'] as int;
        if (totalLeads.value > 0) {
          leadsAssigned.value = ((assignedCount / totalLeads.value) * 100).toInt();
        } else {
          leadsAssigned.value = 0;
        }

        teamPerformance.value = (stats['performance'] as num).toDouble().toPrecision(1);

        // Fetch real team members and their activity
        final team = await _leadService.getManagerTeamStats(managerId);
        if (team.isNotEmpty) {
          teamMembers.value = team;
        }
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
