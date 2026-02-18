import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class SuperAdminDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxInt totalManagers = 0.obs;
  final RxInt totalEmployees = 0.obs;
  final RxInt totalLeads = 0.obs;
  final RxList<ManagerModel> recentManagers = <ManagerModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    try {
      isLoading.value = true;
      
      // Fetch stats and managers in parallel
      final results = await Future.wait([
        _leadService.getGlobalStats(),
        _leadService.getAllManagers(),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final managers = results[1] as List<ManagerModel>;

      totalManagers.value = stats['manager_count'] ?? 0;
      totalEmployees.value = stats['employee_count'] ?? 0;
      totalLeads.value = stats['lead_count'] ?? 0;
      
      // For "Recent Managers", we show the top 5
      recentManagers.value = managers.take(5).toList();
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to load dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    _authService.logout();
  }
}
