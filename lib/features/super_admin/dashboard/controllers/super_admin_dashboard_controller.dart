import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class SuperAdminDashboardController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthService _authService = Get.find<AuthService>();
  
  final RxInt currentTabIndex = 0.obs;
  
  void switchTab(int index) {
    currentTabIndex.value = index;
  }

  final RxInt totalManagers = 0.obs;
  final RxInt totalEmployees = 0.obs;
  final RxInt totalLeads = 0.obs;
  final RxInt totalAgencies = 0.obs;
  final RxList<ManagerModel> recentManagers = <ManagerModel>[].obs;
  final RxList<ProjectModel> recentProjects = <ProjectModel>[].obs;
  final RxBool isLoading = false.obs;

  // Track whether initial data has been loaded
  bool _hasLoadedData = false;

  @override
  void onInit() {
    super.onInit();
    // Listen for SA auth changes so we reload when auth is ready
    ever(_authService.currentSuperAdmin, (_) {
      if (!_hasLoadedData) {
        refreshDashboard();
      }
    });
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    try {
      isLoading.value = true;
      
      final saId = _authService.currentSuperAdmin.value?.id;

      // If SA ID isn't available yet, wait briefly for auth to resolve
      if (saId == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        final retryId = _authService.currentSuperAdmin.value?.id;
        if (retryId == null) {
          // Still no SA — will re-trigger when the ever() listener fires
          isLoading.value = false;
          return;
        }
        return _loadData(retryId);
      }

      return _loadData(saId);
    } catch (e) {
      print('Error refreshing SA dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadData(String saId) async {
    try {
      // Fetch stats, managers, and projects in parallel
      final results = await Future.wait([
        _leadService.getGlobalStats(superAdminId: saId),
        _leadService.getNetworkManagers(currentSuperAdminId: saId),
        _projectService.getProjectsForSuperAdmin(saId),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      final managers = results[1] as List<ManagerModel>;
      final projects = results[2] as List<ProjectModel>;

      totalManagers.value = stats['manager_count'] ?? 0;
      totalEmployees.value = stats['employee_count'] ?? 0;
      totalLeads.value = stats['lead_count'] ?? 0;
      totalAgencies.value = stats['agency_count'] ?? 0;
      
      // For "Recent Managers", show top 5
      recentManagers.value = managers.take(5).toList();
      
      // For "Recent Projects", show top 3
      recentProjects.value = projects.take(3).toList();

      _hasLoadedData = true;
    } catch (e) {
      print('Error loading SA dashboard data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    _authService.logout();
  }
}
