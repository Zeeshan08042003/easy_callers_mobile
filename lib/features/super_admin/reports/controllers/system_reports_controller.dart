import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class SystemReportsController extends GetxController {
  final WebService _webService = Get.find<WebService>();
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList regionalPerformance = <Map<String, dynamic>>[].obs;
  final RxMap globalStats = <String, dynamic>{}.obs;
  final RxList<ProjectModel> availableProjects = <ProjectModel>[].obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      isLoading.value = true;
      
      final saId = _authService.currentSuperAdmin.value?.id;
      if (saId != null) {
        availableProjects.value = await _projectService.getProjectsForSuperAdmin(saId);
      }
      
      await fetchReports();
    } catch (e) {
      print('Error loading system reports data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void onProjectSelected(ProjectModel? project) {
    selectedProject.value = project;
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      isLoading.value = true;
      final projectId = selectedProject.value?.id;
      final saId = _authService.currentSuperAdmin.value?.id;
      final results = await Future.wait([
        _webService.getGlobalStats(projectId: projectId, superAdminId: saId),
        _webService.getRegionalPerformance(
          projectId: projectId,
          currentSuperAdminId: saId,
        ),
      ]);

      globalStats.value = results[0] as Map<String, dynamic>;
      regionalPerformance.value = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load system reports: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
