import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

enum DistributionMethod { equal, custom }

class DistributeLeadsController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final Rx<LeadBatchModel?> mesh = Rx<LeadBatchModel?>(null);
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxMap<String, int> allocations = <String, int>{}.obs; // employeeId -> leadCount
  
  final Rx<DistributionMethod> method = DistributionMethod.equal.obs;
  final RxBool isDistributing = false.obs;
  final RxInt totalBatchLeads = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // In a real flow, we'd pass the batch as an argument
    if (Get.arguments != null && Get.arguments is LeadBatchModel) {
      mesh.value = Get.arguments as LeadBatchModel;
      totalBatchLeads.value = mesh.value!.totalLeads;
    }
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      isDistributing.value = true;
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) return;

      final result = await _leadService.getEmployeesByManager(managerId);
      
      // Filter to only active employees (callers)
      employees.value = result.where((emp) => emp.isActive).toList();
      
      if (employees.isEmpty) {
        Get.snackbar(
          'No Active Employees',
          'You need at least one active employee to distribute leads',
          snackPosition: SnackPosition.BOTTOM,
        );
        isDistributing.value = false;
        return;
      }
      
      // Initialize equal distribution
      _calculateEqualDistribution();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch employees: $e');
    } finally {
      isDistributing.value = false;
    }
  }

  void setMethod(DistributionMethod m) {
    method.value = m;
    if (m == DistributionMethod.equal) {
      _calculateEqualDistribution();
    }
  }

  void _calculateEqualDistribution() {
    if (employees.isEmpty || totalBatchLeads.value == 0) return;
    
    final perEmployee = totalBatchLeads.value ~/ employees.length;
    final remainder = totalBatchLeads.value % employees.length;

    final newAllocations = <String, int>{};
    for (int i = 0; i < employees.length; i++) {
      newAllocations[employees[i].id] = perEmployee + (i < remainder ? 1 : 0);
    }
    allocations.value = newAllocations;
  }

  void updateCustomAllocation(String employeeId, int count) {
    if (method.value != DistributionMethod.custom) return;
    
    // Ensure we don't exceed batch total
    final othersSum = allocations.entries
        .where((e) => e.key != employeeId)
        .fold<int>(0, (sum, e) => sum + e.value);
    
    final maxAllowed = totalBatchLeads.value - othersSum;
    allocations[employeeId] = count.clamp(0, maxAllowed);
  }

  int get currentlyAllocated => allocations.values.fold<int>(0, (sum, count) => sum + count);

  Future<void> executeDistribution() async {
    final batch = mesh.value;
    if (batch == null) return;

    if (currentlyAllocated == 0) {
      Get.snackbar('Nothing to allocate', 'Please allocate at least one lead');
      return;
    }

    try {
      isDistributing.value = true;
      
      // 1. Get unassigned lead IDs from this batch
      final leadIds = await _leadService.getUnassignedLeadsFromBatch(batch.id);
      
      if (leadIds.isEmpty) {
        Get.snackbar('Conflict', 'All leads in this batch are already assigned');
        Get.back();
        return;
      }

      // 2. Filter allocations to only those with > 0 leads
      final activeAllocations = Map<String, int>.from(allocations)
        ..removeWhere((key, value) => value == 0);

      // 3. Execute split
      final success = await _leadService.splitLeadsCustom(
        leadIds: leadIds,
        employeeLeadCounts: activeAllocations,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success', 
          'Successfully distributed $currentlyAllocated leads among ${activeAllocations.length} agents',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar('Error', 'Distribution failed. Please try again.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Distribution failed: $e');
    } finally {
      isDistributing.value = false;
    }
  }
}
