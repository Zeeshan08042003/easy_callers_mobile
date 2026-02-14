import 'package:get/get.dart';
import 'package:easy_callers_mobile/core/models/lead_model.dart';
import 'package:easy_callers_mobile/core/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class EmployeeDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<LeadModel> assignedLeads = <LeadModel>[].obs;
  final RxList<LeadModel> pendingFollowups = <LeadModel>[].obs;
  final RxMap<String, dynamic> todayStats = <String, dynamic>{}.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    try {
      isLoading.value = true;
      final employeeId = _authService.currentEmployee.value?.id;
      if (employeeId == null) return;

      // Parallel fetch
      final results = await Future.wait([
        _leadService.getLeadsByEmployee(employeeId),
        _leadService.getFollowUpsByEmployee(employeeId),
        _leadService.getEmployeeStats(employeeId),
      ]);

      assignedLeads.value = results[0] as List<LeadModel>;
      pendingFollowups.value = results[1] as List<LeadModel>;
      todayStats.value = results[2] as Map<String, dynamic>;

    } catch (e) {
      Get.snackbar('Error', 'Failed to refresh dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int get totalCallsToday => todayStats['calls_today'] ?? 0;
  int get interestedLeads => todayStats['interested_today'] ?? 0;
  double get conversionRate => todayStats['conversion_rate'] ?? 0.0;
}
