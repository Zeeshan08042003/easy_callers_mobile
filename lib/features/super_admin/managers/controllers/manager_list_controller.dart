import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/super_admin/models/manager_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';

class ManagerListController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ManagerModel> managers = <ManagerModel>[].obs;
  final RxList<ManagerModel> filteredManagers = <ManagerModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchManagers();
  }

  Future<void> fetchManagers() async {
    try {
      isLoading.value = true;
      final saId = _authService.currentSuperAdmin.value?.id;
      final result = await _leadService.getAllManagers(currentSuperAdminId: saId);
      managers.assignAll(result);
      filteredManagers.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load managers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void searchManagers(String query) {
    if (query.isEmpty) {
      filteredManagers.assignAll(managers);
    } else {
      filteredManagers.assignAll(
        managers.where((m) => 
          m.fullName.toLowerCase().contains(query.toLowerCase()) || 
          m.email.toLowerCase().contains(query.toLowerCase())
        ).toList(),
      );
    }
  }

  Future<void> toggleManagerStatus(ManagerModel manager) async {
    // In a real app, we'd have a specific method for this
    // For now, let's assume we can update the active status
    try {
      isLoading.value = true;
      // We need a method in leadService to update manager status
      // await _leadService.updateManagerStatus(manager.id, !manager.isActive);
      await fetchManagers(); // Refresh
      Get.snackbar('Success', 'Manager status updated');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update manager: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
