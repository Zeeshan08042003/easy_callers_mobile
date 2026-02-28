import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/project/models/project_model.dart';
import 'package:easy_callers_mobile/features/project/models/project_member_model.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/project/services/project_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';
import 'package:easy_callers_mobile/features/manager/dashboard/controllers/manager_dashboard_controller.dart';

import '../../../core/theme/app_colors.dart';

/// Controller for the project list view.
/// Handles fetching, searching, and filtering projects.
class ProjectListController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<ProjectModel> filteredProjects = <ProjectModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Pending invitations count (for badge)
  final RxInt pendingInvitationCount = 0.obs;
  final RxList<ProjectMemberModel> pendingInvitations = <ProjectMemberModel>[].obs;
  
  // Optional manager ID for Super Admin oversight
  String? oversightManagerId;

  // Debounce: avoid rapid refetching when tab switches quickly
  DateTime? _lastRefresh;

  /// Called by the view every time it becomes visible (tab switch).
  /// Only re-fetches if at least 3 seconds have passed since the last fetch.
  void refreshIfNeeded() {
    final now = DateTime.now();
    if (_lastRefresh == null || now.difference(_lastRefresh!).inSeconds >= 3) {
      _lastRefresh = now;
      fetchProjects();
    }
  }

  @override
  void onInit() {
    super.onInit();
    
    // Check for oversight mode
    if (Get.arguments is String) {
      oversightManagerId = Get.arguments as String;
    } else if (Get.arguments is ManagerModel) {
      oversightManagerId = (Get.arguments as ManagerModel).id;
    }

    fetchProjects();
    if (_authService.currentRole.value == UserRole.manager || 
        _authService.currentRole.value == UserRole.agency || 
        oversightManagerId != null) {
      fetchPendingInvitations();
    }
  }

  Future<void> fetchProjects() async {
    try {
      isLoading.value = true;

      final role = _authService.currentRole.value;

      if (oversightManagerId != null) {
        // Oversight mode: fetch projects for the targeted manager
        projects.value = await _projectService.getProjectsForManager(oversightManagerId!);
      } else if (role == UserRole.superAdmin) {
        final saId = _authService.currentSuperAdmin.value?.id;
        if (saId == null) return;
        projects.value = await _projectService.getProjectsForSuperAdmin(saId);
      } else if (role == UserRole.manager || role == UserRole.agency) {
        final mgrId = _authService.currentManager.value?.id;
        if (mgrId == null) return;
        projects.value = await _projectService.getProjectsForManager(mgrId);
      }

      _applySearch();

      // Also refresh pending invitations for managers
      if (role == UserRole.manager || role == UserRole.agency || oversightManagerId != null) {
        fetchPendingInvitations();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load projects: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPendingInvitations() async {
    try {
      final mgrId = oversightManagerId ?? _authService.currentManager.value?.id;
      if (mgrId == null) return;

      pendingInvitations.value = await _projectService.getPendingInvitations(mgrId);
      pendingInvitationCount.value = pendingInvitations.length;
    } catch (e) {
      print('Error fetching pending invitations: $e');
    }
  }

  Future<void> acceptInvitation(ProjectMemberModel invitation) async {
    try {
      final success = await _projectService.acceptInvitation(invitation.id);
      if (success) {
        Get.snackbar('Success', 'Invitation accepted! You are now a member of "${invitation.projectName}"');
        await fetchPendingInvitations();
        await fetchProjects();

        // Also refresh the dashboard controller so the new project
        // appears in the project selector immediately
        if (Get.isRegistered<ManagerDashboardController>()) {
          Get.find<ManagerDashboardController>().refreshAfterInvitation();
        }
      } else {
        Get.snackbar('Error', 'Failed to accept invitation. Please try again.',
            backgroundColor: AppColors.danger.withOpacity(0.1),
            colorText: AppColors.danger);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation: $e');
    }
  }

  Future<void> declineInvitation(ProjectMemberModel invitation) async {
    try {
      final success = await _projectService.declineInvitation(invitation.id);
      if (success) {
        Get.snackbar('Done', 'Invitation declined');
        await fetchPendingInvitations();
      } else {
        Get.snackbar('Error', 'Failed to decline invitation. Please try again.',
            backgroundColor: AppColors.danger.withOpacity(0.1),
            colorText: AppColors.danger);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation: $e');
    }
  }

  void searchProjects(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    if (searchQuery.value.isEmpty) {
      filteredProjects.value = projects.toList();
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredProjects.value = projects.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.subtitle?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  bool get isSuperAdmin => _authService.currentRole.value == UserRole.superAdmin && oversightManagerId == null;
  bool get isManager => _authService.currentRole.value == UserRole.manager || 
                     _authService.currentRole.value == UserRole.agency || 
                     oversightManagerId != null;
}
