import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/services/supabase_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/models/employee_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';

import '../../../../core/utils/enums.dart';

class DistributionDetailsController extends GetxController {
  final SupabaseService _supabase = Get.find<SupabaseService>();
  final WebService _webService = Get.find<WebService>();
  final AuthService _authService = Get.find<AuthService>();

  late final LeadBatchModel batch;

  final RxBool isLoading = true.obs;
  
  // Stats per employee: { 'employee': EmployeeModel, 'assigned': int, 'contacted': int }
  final RxList<Map<String, dynamic>> employeeStats = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    batch = Get.arguments as LeadBatchModel;
    fetchDistributionDetails();
  }

  Future<void> fetchDistributionDetails() async {
    try {
      isLoading.value = true;
      
      final managerId = _authService.currentManager.value?.id;
      final isSuperAdmin = _authService.currentRole.value == UserRole.superAdmin;

      List<EmployeeModel> employees;
      if (isSuperAdmin && batch.projectId != null) {
        employees = (await _webService.getEmployeesByProject(batch.projectId!)).payload ?? [];
      } else if (managerId != null) {
        employees = (await _webService.getEmployeesByManager(managerId)).payload ?? [];
      } else {
        isLoading.value = false;
        return;
      }
      
      final employeeMap = {for (var e in employees) e.id: e};

      // Fetch all leads for this batch to get counts
      final response = await _supabase.leadsTable
          .select('id, status, assigned_to')
          .eq('batch_id', batch.id);
          
      final leads = response as List;
      
      final Map<String, Map<String, dynamic>> statsMap = {};
      
      for (final lead in leads) {
        final assignedTo = lead['assigned_to'] as String?;
        if (assignedTo == null) continue;
        
        if (!statsMap.containsKey(assignedTo)) {
          if (!employeeMap.containsKey(assignedTo)) continue; // shouldn't happen
          statsMap[assignedTo] = {
            'employee': employeeMap[assignedTo],
            'assigned': 0,
            'contacted': 0,
          };
        }
        
        statsMap[assignedTo]!['assigned'] = (statsMap[assignedTo]!['assigned'] as int) + 1;
        
        final status = lead['status'] as String?;
        if (status != null && status != 'new' && status != 'assigned') {
          statsMap[assignedTo]!['contacted'] = (statsMap[assignedTo]!['contacted'] as int) + 1;
        }
      }

      final sortedStats = statsMap.values.toList()
        ..sort((a, b) => (b['assigned'] as int).compareTo(a['assigned'] as int));
        
      employeeStats.value = sortedStats;
    } catch (e) {
      print('Error fetching distribution details: $e');
      Get.snackbar('Error', 'Could not load distribution details');
    } finally {
      isLoading.value = false;
    }
  }
}
