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
  final RxString projectId = ''.obs;
  final RxString projectName = ''.obs;
  final RxString managerId = ''.obs;
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxMap<String, int> allocations = <String, int>{}.obs; // employeeId -> leadCount
  
  final Rx<DistributionMethod> method = DistributionMethod.equal.obs;
  final RxBool isDistributing = false.obs;
  final RxInt totalBatchLeads = 0.obs;

  @override
  void onInit() {
    super.onInit();
    
    if (Get.arguments != null) {
      if (Get.arguments is LeadBatchModel) {
        // Direct batch distribution
        mesh.value = Get.arguments as LeadBatchModel;
        projectId.value = mesh.value?.projectId ?? '';
        projectName.value = mesh.value?.fileName ?? 'Lead Batch';
        managerId.value = mesh.value?.uploadedBy ?? '';
        // Don't set totalBatchLeads here, let _fetchUnassignedCount handle it
      } else if (Get.arguments is Map) {
        final args = Get.arguments as Map;
        
        if (args.containsKey('batch') && args['batch'] is LeadBatchModel) {
          mesh.value = args['batch'] as LeadBatchModel;
        }
        
        projectId.value = args['projectId'] ?? mesh.value?.projectId ?? '';
        projectName.value = args['projectName'] ?? mesh.value?.fileName ?? 'Leads';
        managerId.value = args['managerId'] ?? mesh.value?.uploadedBy ?? '';
        
        if (args.containsKey('totalUnassigned')) {
          totalBatchLeads.value = args['totalUnassigned'] as int;
          // If project-wide distribution is intended (passed from dashboard),
          // we should NOT use the single batch logic during execution.
          if (args.containsKey('totalUnassigned') && mesh.value != null) {
             // If we have both, but this is a project-wide count, 
             // we null out mesh for executeDistribution to use projectId instead.
             if (totalBatchLeads.value != mesh.value!.totalLeads) {
                // Actually, just let executeDistribution decide based on projectId.isNotEmpty
             }
          }
        }
      }
    }
    
    // Always fetch unassigned count if we don't have it or if we have a direct batch
    if (totalBatchLeads.value == 0 || mesh.value != null) {
      _fetchUnassignedCount();
    }
    
    fetchEmployees();
  }

  Future<void> _fetchUnassignedCount() async {
    try {
      if (mesh.value != null) {
        final ids = await _leadService.getUnassignedLeadsFromBatch(mesh.value!.id);
        totalBatchLeads.value = ids.length;
      } else if (projectId.value.isNotEmpty) {
        final ids = await _leadService.getUnassignedLeadsForProject(projectId.value);
        totalBatchLeads.value = ids.length;
      }
      
      // Re-calculate distribution if already loaded
      if (employees.isNotEmpty) {
        _calculateEqualDistribution();
      }
    } catch (e) {
      print('Error fetching unassigned count: $e');
    }
  }

  Future<void> fetchEmployees() async {
    try {
      isDistributing.value = true;
      
      // Use passed managerId first (for SA oversight), fallback to current manager
      final mId = managerId.value.isNotEmpty 
          ? managerId.value 
          : _authService.currentManager.value?.id;
          
      if (mId == null) {
        print('❌ Error: No manager context for distribution');
        isDistributing.value = false;
        return;
      }

      final projectID = projectId.value.isNotEmpty ? projectId.value : mesh.value?.projectId;

      print("Project Id : $projectID");

      List<EmployeeModel> result;

      if (projectID != null && projectID.isNotEmpty) {
        // Project-based: only load callers assigned to this project
        result = await _leadService.getProjectCallersByManager(
          projectId: projectID,
          managerId: mId,
        );
      } else {
        // Legacy/Generic: load all active employees
        result = await _leadService.getEmployeesByManager(mId);
        result = result.where((emp) => emp.isActive).toList();
      }

      employees.value = result;

      if (employees.isEmpty) {
        Get.snackbar(
          'No Active Callers',
          projectID != null && projectID.isNotEmpty
              ? 'No callers are assigned to this project. Add callers in the project settings first.'
              : 'You need at least one active caller to distribute leads',
          snackPosition: SnackPosition.BOTTOM,
        );
        isDistributing.value = false;
        return;
      }

      // Initialize equal distribution
      _calculateEqualDistribution();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch callers: $e');
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
    if (currentlyAllocated == 0) {
      Get.snackbar('Nothing to allocate', 'Please allocate at least one lead');
      return;
    }

    try {
      isDistributing.value = true;
      
      List<String> leadIds = [];
      
      // If we have a projectId AND we are NOT specifically trying to distribute a single batch,
      // distribute ALL unassigned leads in the project.
      if (projectId.value.isNotEmpty && mesh.value == null) {
        leadIds = await _leadService.getUnassignedLeadsForProject(projectId.value);
      } else if (mesh.value != null) {
        leadIds = await _leadService.getUnassignedLeadsFromBatch(mesh.value!.id);
      } else if (projectId.value.isNotEmpty) {
        // Fallback for project distribution even if mesh exists (if opened from dashboard)
        leadIds = await _leadService.getUnassignedLeadsForProject(projectId.value);
      }
      
      if (leadIds.isEmpty) {
        Get.snackbar('Conflict', 'No unassigned leads found for this ${mesh.value != null ? 'batch' : 'project'}.');
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
