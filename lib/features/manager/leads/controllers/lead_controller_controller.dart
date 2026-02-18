import 'package:get/get.dart';
import 'package:easy_callers_mobile/features/manager/models/lead_model.dart';
import 'package:easy_callers_mobile/features/manager/services/lead_service.dart';
import 'package:easy_callers_mobile/core/services/auth_service.dart';
import 'package:easy_callers_mobile/core/utils/enums.dart';

import 'package:easy_callers_mobile/features/manager/models/lead_batch_model.dart';
import 'package:easy_callers_mobile/features/manager/leads/views/distribute_leads_view.dart';
import 'package:easy_callers_mobile/features/manager/leads/bindings/distribute_leads_binding.dart';
import 'package:easy_callers_mobile/app/routes/app_routes.dart';

class LeadControllerController extends GetxController {
  final LeadService _leadService = Get.find<LeadService>();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<LeadModel> leads = <LeadModel>[].obs;
  final RxList<LeadModel> filteredLeads = <LeadModel>[].obs;
  final RxBool isLoading = false.obs;
  
  final Rx<LeadStatus?> activeFilter = Rx<LeadStatus?>(null);
  final RxString searchQuery = ''.obs;

  // If viewing as Super Admin, we might have a target manager
  String? targetManagerId;

  @override
  void onInit() {
    super.onInit();
    // Get target manager from arguments if any
    if (Get.arguments != null && Get.arguments is String) {
      targetManagerId = Get.arguments as String;
    }
    fetchLeads();
  }

  Future<void> fetchLeads() async {
    try {
      isLoading.value = true;
      final managerId = targetManagerId ?? _authService.currentManager.value?.id;
      
      if (managerId == null) return;

      final result = await _leadService.getLeadsByManager(managerId);
      leads.value = result;
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load leads: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadLeads() async {
    try {
      final managerId = _authService.currentManager.value?.id;
      if (managerId == null) return;

      isLoading.value = true;
      final batch = await _leadService.pickAndUploadLeads(managerId);
      
      if (batch != null) {
        Get.snackbar('Success', 'Uploaded ${batch.totalLeads} leads successfully!');
        // Refresh leads list
        await fetchLeads();
        // Option to go to distribution screen
        Get.to(() => const DistributeLeadsView(), binding: DistributeLeadsBinding(), arguments: batch);
      }
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(LeadStatus? status) {
    if (activeFilter.value == status) {
      activeFilter.value = null; // Toggle off
    } else {
      activeFilter.value = status;
    }
    _applyFilters();
  }

  void searchLeads(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void _applyFilters() {
    var result = leads.toList();

    // Apply Status Filter
    if (activeFilter.value != null) {
      result = result.where((l) => l.status == activeFilter.value).toList();
    }

    // Apply Search
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((l) {
        return l.name.toLowerCase().contains(query) ||
               (l.phone.contains(query)) ||
               (l.projectName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    filteredLeads.value = result;
  }
}
